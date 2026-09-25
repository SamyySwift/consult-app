import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

export const mapsRouter = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

interface RoadRoute {
  coordinates: [number, number][]; // [lat, lng]
  distance_m: number;
  duration_s: number;
}

// Road routes rarely change, so each origin/destination pair is fetched from
// Mapbox once and reused. Keys round to 4 decimals (~11 m).
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const CACHE_MAX_ENTRIES = 1000;
const routeCache = new Map<string, { route: RoadRoute; at: number }>();

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

  const token = process.env.MAPBOX_TOKEN;
  if (!token) {
    res.status(503).json({ error: 'Routing not configured' });
    return;
  }

  const key = [...from, ...to].map((n) => n.toFixed(4)).join(',');
  const cached = routeCache.get(key);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) {
    res.json(cached.route);
    return;
  }

  try {
    const coords = `${from[1]},${from[0]};${to[1]},${to[0]}`;
    const url =
      `https://api.mapbox.com/directions/v5/mapbox/driving/${coords}` +
      `?geometries=geojson&overview=full&access_token=${encodeURIComponent(token)}`;
    const mapboxRes = await fetch(url);
    const body: any = await mapboxRes.json();

    const best = body?.routes?.[0];
    if (!mapboxRes.ok || !best) {
      console.error('Mapbox directions failed:', mapboxRes.status, body?.message ?? body?.code);
      res.status(502).json({ error: 'No route found' });
      return;
    }

    const route: RoadRoute = {
      // GeoJSON is [lng, lat]; the app works in [lat, lng].
      coordinates: best.geometry.coordinates.map(([lng, lat]: [number, number]) => [lat, lng]),
      distance_m: best.distance,
      duration_s: best.duration,
    };

    if (routeCache.size >= CACHE_MAX_ENTRIES) {
      // Maps iterate in insertion order, so the first key is the oldest.
      routeCache.delete(routeCache.keys().next().value!);
    }
    routeCache.set(key, { route, at: Date.now() });

    res.json(route);
  } catch (err: any) {
    console.error('Error fetching route:', err);
    res.status(502).json({ error: 'Failed to fetch route: ' + err.message });
  }
});
