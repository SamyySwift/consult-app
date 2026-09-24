import fs from 'fs';
import path from 'path';
import { Readable } from 'stream';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3Bucket = process.env.S3_BUCKET;
const s3Endpoint = process.env.S3_ENDPOINT || 'https://t3.storageapi.dev';
const s3Region = process.env.S3_REGION || 'auto';
const s3AccessKeyId = process.env.S3_ACCESS_KEY_ID;
const s3SecretAccessKey = process.env.S3_SECRET_ACCESS_KEY;

export const isS3Configured = Boolean(
  s3Bucket && s3AccessKeyId && s3SecretAccessKey
);

let s3Client: S3Client | null = null;
if (isS3Configured) {
  s3Client = new S3Client({
    endpoint: s3Endpoint,
    region: s3Region,
    credentials: {
      accessKeyId: s3AccessKeyId!,
      secretAccessKey: s3SecretAccessKey!,
    },
    forcePathStyle: false,
  });
}

// Local storage fallback directory
const localUploadsDir = path.join(process.cwd(), 'uploads');
if (!isS3Configured && !fs.existsSync(localUploadsDir)) {
  try {
    fs.mkdirSync(localUploadsDir, { recursive: true });
  } catch (err) {
    console.error('Failed to create local uploads directory:', err);
  }
}

export interface UploadResult {
  key: string;
  url: string;
  bucket: string;
  size: number;
  contentType: string;
  isS3: boolean;
}

/**
 * Upload a file Buffer to S3 bucket or local storage fallback.
 */
export async function uploadToStorage(
  buffer: Buffer,
  key: string,
  contentType: string,
  baseUrl: string
): Promise<UploadResult> {
  const cleanKey = key.replace(/^\/+/, '');

  if (isS3Configured && s3Client) {
    await s3Client.send(
      new PutObjectCommand({
        Bucket: s3Bucket!,
        Key: cleanKey,
        Body: buffer,
        ContentType: contentType,
      })
    );

    const publicUrl = `${baseUrl}/api/files/${encodeURIComponent(cleanKey)}`;
    return {
      key: cleanKey,
      url: publicUrl,
      bucket: s3Bucket!,
      size: buffer.length,
      contentType,
      isS3: true,
    };
  } else {
    // Local storage fallback
    const targetPath = path.join(localUploadsDir, cleanKey);
    const targetDir = path.dirname(targetPath);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }
    fs.writeFileSync(targetPath, buffer);

    const publicUrl = `${baseUrl}/api/files/${encodeURIComponent(cleanKey)}`;
    return {
      key: cleanKey,
      url: publicUrl,
      bucket: 'local-disk',
      size: buffer.length,
      contentType,
      isS3: false,
    };
  }
}

/**
 * Retrieve file stream and metadata from S3 bucket or local storage fallback.
 */
export async function getFromStorage(key: string): Promise<{
  stream: Readable;
  contentType: string;
  contentLength?: number;
} | null> {
  const cleanKey = key.replace(/^\/+/, '');

  if (isS3Configured && s3Client) {
    try {
      const response = await s3Client.send(
        new GetObjectCommand({
          Bucket: s3Bucket!,
          Key: cleanKey,
        })
      );

      if (!response.Body) return null;

      return {
        stream: response.Body as Readable,
        contentType: response.ContentType || 'application/octet-stream',
        contentLength: response.ContentLength,
      };
    } catch (err: any) {
      if (err.name === 'NoSuchKey' || err.$metadata?.httpStatusCode === 404) {
        return null;
      }
      throw err;
    }
  } else {
    // Local storage fallback
    const targetPath = path.join(localUploadsDir, cleanKey);
    if (!fs.existsSync(targetPath)) return null;

    const stats = fs.statSync(targetPath);
    const ext = path.extname(cleanKey).toLowerCase();
    const contentTypeMap: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.pdf': 'application/pdf',
      '.svg': 'image/svg+xml',
    };

    return {
      stream: fs.createReadStream(targetPath),
      contentType: contentTypeMap[ext] || 'application/octet-stream',
      contentLength: stats.size,
    };
  }
}

/**
 * Generate a presigned S3 upload URL for direct client uploads.
 */
export async function createPresignedUploadUrl(
  key: string,
  contentType: string,
  expiresInSeconds = 3600
): Promise<{ uploadUrl: string; key: string } | null> {
  if (!isS3Configured || !s3Client) return null;

  const cleanKey = key.replace(/^\/+/, '');
  const command = new PutObjectCommand({
    Bucket: s3Bucket!,
    Key: cleanKey,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: expiresInSeconds,
  });

  return { uploadUrl, key: cleanKey };
}

/**
 * Delete a file from S3 or local storage.
 */
export async function deleteFromStorage(key: string): Promise<boolean> {
  const cleanKey = key.replace(/^\/+/, '');

  if (isS3Configured && s3Client) {
    try {
      await s3Client.send(
        new DeleteObjectCommand({
          Bucket: s3Bucket!,
          Key: cleanKey,
        })
      );
      return true;
    } catch {
      return false;
    }
  } else {
    const targetPath = path.join(localUploadsDir, cleanKey);
    if (fs.existsSync(targetPath)) {
      fs.unlinkSync(targetPath);
      return true;
    }
    return false;
  }
}
