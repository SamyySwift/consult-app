import { WebSocketServer, WebSocket } from 'ws';
import type { Server } from 'http';
import jwt from 'jsonwebtoken';
import { pool } from './db';

const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

const HEARTBEAT_INTERVAL_MS = 30_000;
// Clients get one frame to authenticate before we drop them, so an unauthenticated
// socket can't sit open holding a slot.
const AUTH_TIMEOUT_MS = 10_000;

interface TrackedClient {
  socket: WebSocket;
  userId: string | null;
  bookingIds: Set<string>;
  isAlive: boolean;
}

const clients = new Set<TrackedClient>();

function send(client: TrackedClient, payload: Record<string, unknown>) {
  if (client.socket.readyState === WebSocket.OPEN) {
    client.socket.send(JSON.stringify(payload));
  }
}

/**
 * Pushes a driver position to every authenticated socket subscribed to that booking.
 * Called by the driver location endpoint after the row is written.
 */
export function broadcastDriverLocation(bookingId: string, lat: number, lng: number) {
  const payload = JSON.stringify({
    type: 'driver_location',
    bookingId,
    lat,
    lng,
    at: new Date().toISOString(),
  });

  for (const client of clients) {
    if (
      client.userId &&
      client.bookingIds.has(bookingId) &&
      client.socket.readyState === WebSocket.OPEN
    ) {
      client.socket.send(payload);
    }
  }
}

async function userCanTrackBooking(userId: string, bookingId: string): Promise<boolean> {
  try {
    const result = await pool.query(
      `SELECT 1 FROM public.bookings WHERE id = $1 AND (user_id = $2 OR driver_id = $2) LIMIT 1`,
      [bookingId, userId]
    );
    return result.rows.length > 0;
  } catch (err) {
    // A malformed UUID makes Postgres throw rather than return zero rows.
    return false;
  }
}

async function handleMessage(client: TrackedClient, raw: string) {
  let msg: any;
  try {
    msg = JSON.parse(raw);
  } catch (_) {
    send(client, { type: 'error', error: 'Malformed JSON' });
    return;
  }

  switch (msg?.type) {
    case 'auth': {
      try {
        const decoded = jwt.verify(String(msg.token || ''), JWT_SECRET) as { id: string };
        client.userId = decoded.id;
        send(client, { type: 'auth_ok' });
      } catch (_) {
        send(client, { type: 'auth_error', error: 'Invalid or expired token' });
        client.socket.close(4001, 'Unauthorized');
      }
      return;
    }

    case 'subscribe': {
      if (!client.userId) {
        send(client, { type: 'error', error: 'Not authenticated' });
        return;
      }
      const bookingId = String(msg.bookingId || '');
      if (!bookingId) {
        send(client, { type: 'error', error: 'bookingId is required' });
        return;
      }
      if (!(await userCanTrackBooking(client.userId, bookingId))) {
        send(client, { type: 'error', error: 'Not permitted to track this booking' });
        return;
      }
      client.bookingIds.add(bookingId);
      send(client, { type: 'subscribed', bookingId });
      return;
    }

    case 'unsubscribe': {
      client.bookingIds.delete(String(msg.bookingId || ''));
      return;
    }

    case 'ping': {
      send(client, { type: 'pong' });
      return;
    }

    default:
      send(client, { type: 'error', error: `Unknown message type: ${msg?.type}` });
  }
}

export function attachRealtime(server: Server) {
  const wss = new WebSocketServer({ server, path: '/ws/tracking' });

  wss.on('connection', (socket: WebSocket) => {
    const client: TrackedClient = {
      socket,
      userId: null,
      bookingIds: new Set(),
      isAlive: true,
    };
    clients.add(client);

    const authTimer = setTimeout(() => {
      if (!client.userId) socket.close(4001, 'Authentication timeout');
    }, AUTH_TIMEOUT_MS);

    socket.on('pong', () => {
      client.isAlive = true;
    });

    socket.on('message', (data) => {
      handleMessage(client, data.toString()).catch((err) => {
        console.error('WS message handling failed:', err);
      });
    });

    socket.on('close', () => {
      clearTimeout(authTimer);
      clients.delete(client);
    });

    socket.on('error', (err) => {
      console.error('WS socket error:', err.message);
      clearTimeout(authTimer);
      clients.delete(client);
    });
  });

  // Proxies silently drop idle connections; this detects half-open sockets.
  const heartbeat = setInterval(() => {
    for (const client of clients) {
      if (!client.isAlive) {
        client.socket.terminate();
        clients.delete(client);
        continue;
      }
      client.isAlive = false;
      client.socket.ping();
    }
  }, HEARTBEAT_INTERVAL_MS);

  wss.on('close', () => clearInterval(heartbeat));

  console.log('🔌 WebSocket tracking hub mounted at /ws/tracking');
}
