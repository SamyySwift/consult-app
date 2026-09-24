import { Router, Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import crypto from 'crypto';
import {
  uploadToStorage,
  getFromStorage,
  createPresignedUploadUrl,
  isS3Configured,
} from '../storage';

export const uploadRouter = Router();

// Configure multer for in-memory buffer handling (up to 15MB)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 },
});

function getBaseUrl(req: Request): string {
  if (process.env.PUBLIC_URL) return process.env.PUBLIC_URL.replace(/\/+$/, '');
  const proto = req.headers['x-forwarded-proto'] || req.protocol;
  const host = req.headers['x-forwarded-host'] || req.get('host');
  return `${proto}://${host}`;
}

function generateStorageKey(folder: string, originalName?: string, extension?: string): string {
  const cleanFolder = (folder || 'general').replace(/[^a-zA-Z0-9_\-\/]/g, '').replace(/^\/+|\/+$/g, '');
  const randomSuffix = crypto.randomBytes(6).toString('hex');
  const timestamp = Date.now();
  let ext = extension || '';
  if (!ext && originalName) {
    ext = path.extname(originalName).toLowerCase();
  }
  if (ext && !ext.startsWith('.')) ext = `.${ext}`;

  return `${cleanFolder}/${timestamp}_${randomSuffix}${ext}`;
}

/**
 * POST /api/upload
 * Supports:
 * 1. multipart/form-data with file field 'file'
 * 2. application/json with base64 data URI { file: "data:image/jpeg;base64,...", fileName: "...", folder: "..." }
 */
uploadRouter.post(
  '/',
  upload.single('file'),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const baseUrl = getBaseUrl(req);
      const folder = (req.body.folder as string) || 'uploads';

      // Case 1: Multipart file upload
      if (req.file) {
        const key = generateStorageKey(folder, req.file.originalname);
        const result = await uploadToStorage(
          req.file.buffer,
          key,
          req.file.mimetype || 'application/octet-stream',
          baseUrl
        );

        res.status(201).json({
          success: true,
          ...result,
        });
        return;
      }

      // Case 2: JSON payload with base64 string
      const fileData = req.body.file || req.body.fileBase64 || req.body.image;
      if (typeof fileData === 'string' && fileData.trim().length > 0) {
        let base64Content = fileData;
        let contentType = 'application/octet-stream';
        let ext = '.bin';

        // Check for Data URI format: data:image/png;base64,....
        if (fileData.startsWith('data:')) {
          const match = fileData.match(/^data:([^;]+);base64,(.+)$/);
          if (match) {
            contentType = match[1];
            base64Content = match[2];
            if (contentType.includes('jpeg') || contentType.includes('jpg')) ext = '.jpg';
            else if (contentType.includes('png')) ext = '.png';
            else if (contentType.includes('webp')) ext = '.webp';
            else if (contentType.includes('pdf')) ext = '.pdf';
          }
        }

        const buffer = Buffer.from(base64Content, 'base64');
        const key = generateStorageKey(
          folder,
          req.body.fileName,
          req.body.fileName ? undefined : ext
        );

        const result = await uploadToStorage(buffer, key, contentType, baseUrl);

        res.status(201).json({
          success: true,
          ...result,
        });
        return;
      }

      res.status(400).json({
        success: false,
        error: 'No file uploaded. Provide a multipart file or base64 file data.',
      });
    } catch (err: any) {
      console.error('Upload error:', err);
      res.status(500).json({
        success: false,
        error: err.message || 'File upload failed',
      });
    }
  }
);

/**
 * POST /api/upload/presigned-url
 * Returns a presigned S3 PUT URL for direct client upload
 */
uploadRouter.post(
  '/presigned-url',
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { fileName, contentType, folder } = req.body;
      if (!fileName || !contentType) {
        res.status(400).json({
          success: false,
          error: 'fileName and contentType are required',
        });
        return;
      }

      const key = generateStorageKey(folder || 'uploads', fileName);
      const presigned = await createPresignedUploadUrl(key, contentType, 3600);

      if (!presigned) {
        res.status(501).json({
          success: false,
          error: 'Direct S3 presigned URLs are not available in current configuration',
        });
        return;
      }

      const baseUrl = getBaseUrl(req);
      const publicUrl = `${baseUrl}/api/files/${encodeURIComponent(key)}`;

      res.json({
        success: true,
        uploadUrl: presigned.uploadUrl,
        key: presigned.key,
        fileUrl: publicUrl,
        expiresInSeconds: 3600,
      });
    } catch (err: any) {
      console.error('Presigned URL error:', err);
      res.status(500).json({
        success: false,
        error: err.message || 'Failed to generate presigned upload URL',
      });
    }
  }
);

/**
 * GET /api/upload/status
 * Storage health and configuration info
 */
uploadRouter.get('/status', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    storageType: isS3Configured ? 'railway-s3-bucket' : 'local-disk',
    bucket: process.env.S3_BUCKET || 'carpital-consult-uploads',
    region: process.env.S3_REGION || 'auto',
    isS3Configured,
  });
});

/**
 * Helper to upload a base64 or buffer directly from internal server code
 */
export async function uploadBufferOrBase64(
  data: string | Buffer,
  folder: string,
  preferredName?: string,
  baseUrl = 'https://carpitalconsult.com'
): Promise<string> {
  if (typeof data === 'string') {
    // If it's already a public URL, keep it
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return data;
    }

    let base64 = data;
    let contentType = 'image/jpeg';
    let ext = '.jpg';

    if (data.startsWith('data:')) {
      const match = data.match(/^data:([^;]+);base64,(.+)$/);
      if (match) {
        contentType = match[1];
        base64 = match[2];
        if (contentType.includes('png')) ext = '.png';
        else if (contentType.includes('webp')) ext = '.webp';
        else if (contentType.includes('pdf')) ext = '.pdf';
      }
    }

    const buffer = Buffer.from(base64, 'base64');
    const key = generateStorageKey(folder, preferredName, ext);
    const result = await uploadToStorage(buffer, key, contentType, baseUrl);
    return result.url;
  } else {
    const key = generateStorageKey(folder, preferredName, '.bin');
    const result = await uploadToStorage(data, key, 'application/octet-stream', baseUrl);
    return result.url;
  }
}
