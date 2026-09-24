import { Router, Request, Response } from 'express';
import { getFromStorage } from '../storage';

export const filesRouter = Router();

/**
 * GET /api/files/*
 * Stream files from the S3 bucket or local fallback
 */
filesRouter.get('/*', async (req: Request, res: Response): Promise<void> => {
  try {
    // req.params[0] contains the wildcard path e.g. "licenses/1727161200000_abc123.jpg"
    const fileKey = req.params[0] || req.path.replace(/^\/+/, '');
    if (!fileKey) {
      res.status(400).json({ error: 'File key is required' });
      return;
    }

    const file = await getFromStorage(fileKey);
    if (!file) {
      res.status(404).json({ error: 'File not found' });
      return;
    }

    res.setHeader('Content-Type', file.contentType);
    if (file.contentLength) {
      res.setHeader('Content-Length', file.contentLength);
    }
    // Cache for 30 days
    res.setHeader('Cache-Control', 'public, max-age=2592000, immutable');

    file.stream.pipe(res);
  } catch (err: any) {
    console.error('File retrieval error:', err);
    res.status(500).json({ error: 'Failed to retrieve file' });
  }
});
