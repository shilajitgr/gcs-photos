import { Storage } from "@google-cloud/storage";
import type { ThumbnailFormat, ThumbnailSize } from "../models/photo.js";
import { logger } from "../utils/logger.js";

const storage = new Storage();

/**
 * Download an original image from a user's GCS bucket.
 */
export async function downloadOriginal(
  bucketName: string,
  objectPath: string,
): Promise<Buffer> {
  logger.info("Downloading original from GCS", { bucketName, objectPath });

  const [contents] = await storage
    .bucket(bucketName)
    .file(objectPath)
    .download();

  logger.info("Download complete", {
    bucketName,
    objectPath,
    sizeBytes: contents.byteLength,
  });

  return contents;
}

/**
 * Upload a generated thumbnail to the user's GCS bucket.
 *
 * Thumbnails are stored at:
 *   /thumbnails/{contentHash}_{size}.{format}
 *
 * Content-hash-based paths make CDN cache invalidation unnecessary.
 */
export async function uploadThumbnail(
  bucketName: string,
  contentHash: string,
  size: ThumbnailSize,
  format: ThumbnailFormat,
  buffer: Buffer,
): Promise<string> {
  const extension = format === "avif" ? "avif" : "webp";
  const objectPath = `thumbnails/${contentHash}_${size}.${extension}`;
  const contentType = format === "avif" ? "image/avif" : "image/webp";

  logger.info("Uploading thumbnail to GCS", {
    bucketName,
    objectPath,
    size,
    format,
    sizeBytes: buffer.byteLength,
  });

  const file = storage.bucket(bucketName).file(objectPath);

  await file.save(buffer, {
    metadata: {
      contentType,
      cacheControl: "public, max-age=31536000, immutable",
    },
    resumable: false, // thumbnails are small; skip resumable overhead
  });

  return objectPath;
}
