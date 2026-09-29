import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

export const mapsRouter = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

// Server-only Google key, restricted to Routes API, Places API (New) and
// Geocoding API. The apps never see it.
function googleKey(): string | undefined {
  return process.env.GOOGLE_MAPS_SERVER_KEY || undefined;
}

interface RoadRoute {
  coordinates: [number, number][]; // [lat, lng]
  distance_m: number;
  duration_s: number;
}

interface PlaceHit {
  name: string;
  details: string | null;
  lat: number;
  lng: number;
}

// Road routes rarely change, so each origin/destination pair is fetched from
// Google once and reused. Keys round to 4 decimals (~11 m).
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const CACHE_MAX_ENTRIES = 1000;
const routeCache = new Map<string, { value: RoadRoute; at: number }>();
const reverseCache = new Map<string, { value: PlaceHit | null; at: number }>();

function cacheGet<T>(cache: Map<string, { value: T; at: number }>, key: string): T | undefined {
  const hit = cache.get(key);
  return hit && Date.now() - hit.at < CACHE_TTL_MS ? hit.value : undefined;
}

function cacheSet<T>(cache: Map<string, { value: T; at: number }>, key: string, value: T) {
  if (cache.size >= CACHE_MAX_ENTRIES) {
    // Maps iterate in insertion order, so the first key is the oldest.
    cache.delete(cache.keys().next().value!);
  }
  cache.set(key, { value, at: Date.now() });
}

function parsePoint(value: unknown): [number, number] | null {
  if (typeof value !== 'string') return null;
  const [lat, lng] = value.split(',').map(Number);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return [lat, lng];
}

function isAuthenticated(req: Request): boolean {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return false;
  try {
    jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    return true;
  } catch (_) {
    return false;
  }
}

/** Decodes a Google encoded polyline (precision 5) into [lat, lng] pairs. */
function decodePolyline(encoded: string): [number, number][] {
  const points: [number, number][] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  const next = (): number => {
    let result = 0;
    let shift = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return result & 1 ? ~(result >> 1) : result >> 1;
  };

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.push([lat / 1e5, lng / 1e5]);
  }
  return points;
}

/** Google errors come back as { error: { message } }; log without the key. */
function googleError(body: any): string {
  return body?.error?.message ?? body?.error_message ?? body?.status ?? 'unknown error';
}

// -------------------------------------------------------------
// GET /api/maps/route?from=lat,lng&to=lat,lng - Road route between two points
// -------------------------------------------------------------
mapsRouter.get('/route', async (req: Request, res: Response): Promise<void> => {
  if (!isAuthenticated(req)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const from = parsePoint(req.query.from);
  const to = parsePoint(req.query.to);
  if (!from || !to) {
    res.status(400).json({ error: 'from and to must be "lat,lng"' });
    return;
  }

  const apiKey = googleKey();
  if (!apiKey) {
    res.status(503).json({ error: 'Routing not configured' });
    return;
  }

  const key = [...from, ...to].map((n) => n.toFixed(4)).join(',');
  const cached = cacheGet(routeCache, key);
  if (cached) {
    res.json(cached);
    return;
  }

  try {
    const googleRes = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        // Only what the apps use; the field mask also keeps the request on the cheaper SKU
        'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      },
      body: JSON.stringify({
        origin: { location: { latLng: { latitude: from[0], longitude: from[1] } } },
        destination: { location: { latLng: { latitude: to[0], longitude: to[1] } } },
        travelMode: 'DRIVE',
        routingPreference: 'TRAFFIC_AWARE',
        languageCode: 'en',
        units: 'METRIC',
      }),
    });
    const body: any = await googleRes.json();

    const best = body?.routes?.[0];
    if (!googleRes.ok || !best?.polyline?.encodedPolyline) {
      console.error('Google routing failed:', googleRes.status, googleError(body));
      res.status(502).json({ error: 'No route found' });
      return;
    }

    const route: RoadRoute = {
      coordinates: decodePolyline(best.polyline.encodedPolyline),
      distance_m: best.distanceMeters ?? 0,
      // Durations come back as strings like "1234s"
      duration_s: parseFloat(String(best.duration ?? '0')) || 0,
    };

    cacheSet(routeCache, key, route);
    res.json(route);
  } catch (err: any) {
    console.error('Error fetching route:', err);
    res.status(502).json({ error: 'Failed to fetch route: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/maps/autocomplete?q=text&session=token - Address suggestions
// -------------------------------------------------------------
// Pass the same session token to the matching /place call: Google then bills
// the suggestions and the chosen place as one session.
mapsRouter.get('/autocomplete', async (req: Request, res: Response): Promise<void> => {
  if (!isAuthenticated(req)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  const session = typeof req.query.session === 'string' ? req.query.session : undefined;
  if (q.length < 2) {
    res.json([]);
    return;
  }

  const apiKey = googleKey();
  if (!apiKey) {
    res.status(503).json({ error: 'Address search not configured' });
    return;
  }

  try {
    const googleRes = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
          'suggestions.placePrediction.placeId,suggestions.placePrediction.structuredFormat',
      },
      body: JSON.stringify({
        input: q,
        includedRegionCodes: ['ng'],
        languageCode: 'en',
        ...(session ? { sessionToken: session } : {}),
      }),
    });
    const body: any = await googleRes.json();

    if (!googleRes.ok) {
      console.error('Google autocomplete failed:', googleRes.status, googleError(body));
      res.status(502).json({ error: 'Address search failed' });
      return;
    }

    const suggestions = (body?.suggestions ?? [])
      .map((s: any) => s.placePrediction)
      .filter((p: any) => p?.placeId && p?.structuredFormat?.mainText?.text)
      .map((p: any) => ({
        placeId: p.placeId,
        name: p.structuredFormat.mainText.text,
        details: p.structuredFormat.secondaryText?.text ?? null,
      }));

    res.json(suggestions);
  } catch (err: any) {
    console.error('Error in address search:', err);
    res.status(502).json({ error: 'Address search failed: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/maps/place/:id?session=token - Coordinates of a suggested place
// -------------------------------------------------------------
mapsRouter.get('/place/:id', async (req: Request, res: Response): Promise<void> => {
  if (!isAuthenticated(req)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const placeId = req.params.id;
  if (!/^[\w-]+$/.test(placeId)) {
    res.status(400).json({ error: 'Invalid place id' });
    return;
  }

  const apiKey = googleKey();
  if (!apiKey) {
    res.status(503).json({ error: 'Address search not configured' });
    return;
  }

  try {
    const params = new URLSearchParams({ languageCode: 'en' });
    if (typeof req.query.session === 'string') params.set('sessionToken', req.query.session);

    const googleRes = await fetch(
      `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?${params}`,
      {
        headers: {
          'X-Goog-Api-Key': apiKey,
          // Essentials fields only; the app already has the place's name from the suggestion
          'X-Goog-FieldMask': 'id,formattedAddress,location',
        },
      }
    );
    const body: any = await googleRes.json();

    if (!googleRes.ok || !body?.location) {
      console.error('Google place details failed:', googleRes.status, googleError(body));
      res.status(502).json({ error: 'Could not load that place' });
      return;
    }

    res.json({
      placeId: body.id ?? placeId,
      address: body.formattedAddress ?? null,
      lat: body.location.latitude,
      lng: body.location.longitude,
    });
  } catch (err: any) {
    console.error('Error loading place:', err);
    res.status(502).json({ error: 'Could not load that place: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/maps/reverse?lat=..&lng=.. - Address at a map point
// -------------------------------------------------------------
mapsRouter.get('/reverse', async (req: Request, res: Response): Promise<void> => {
  if (!isAuthenticated(req)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const point = parsePoint(`${req.query.lat},${req.query.lng}`);
  if (!point) {
    res.status(400).json({ error: 'lat and lng are required' });
    return;
  }

  const apiKey = googleKey();
  if (!apiKey) {
    res.status(503).json({ error: 'Address lookup not configured' });
    return;
  }

  // ~11 m buckets: nudging the map pin slightly reuses the same lookup
  const key = point.map((n) => n.toFixed(4)).join(',');
  const cached = cacheGet(reverseCache, key);
  if (cached !== undefined) {
    if (cached) {
      res.json({ ...cached, lat: point[0], lng: point[1] });
    } else {
      res.status(404).json({ error: 'No address here' });
    }
    return;
  }

  try {
    const params = new URLSearchParams({
      latlng: `${point[0]},${point[1]}`,
      language: 'en',
      key: apiKey,
    });
    const googleRes = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?${params}`);
    const body: any = await googleRes.json();

    if (body?.status !== 'OK' && body?.status !== 'ZERO_RESULTS') {
      console.error('Google reverse geocoding failed:', body?.status, body?.error_message);
      res.status(502).json({ error: 'Address lookup failed' });
      return;
    }

    // The first result is often a plus code ("JMR3+2W Ikeja"); prefer a real address
    const result = (body.results ?? []).find((r: any) => !r.types?.includes('plus_code'));
    if (!result?.formatted_address) {
      cacheSet(reverseCache, key, null);
      res.status(404).json({ error: 'No address here' });
      return;
    }

    // "12 Obafemi Awolowo Way, Agidingbi, Ikeja 101233, Lagos, Nigeria"
    // -> name "12 Obafemi Awolowo Way", details "Agidingbi, Ikeja 101233, Lagos"
    const parts = String(result.formatted_address)
      .split(',')
      .map((p) => p.trim())
      .filter((p) => p && p !== 'Nigeria');
    const hit: PlaceHit = {
      name: parts[0] ?? result.formatted_address,
      details: parts.length > 1 ? parts.slice(1).join(', ') : null,
      lat: point[0],
      lng: point[1],
    };

    cacheSet(reverseCache, key, hit);
    // The pin's exact position, not the geocoder's snapped one
    res.json(hit);
  } catch (err: any) {
    console.error('Error in reverse geocoding:', err);
    res.status(502).json({ error: 'Address lookup failed: ' + err.message });
  }
});
