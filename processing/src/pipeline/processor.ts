import type {
  PhotoMetadata,
  ProcessingResult,
  ThumbnailSize,
} from "../models/photo.js";
import type { ProcessingJobMessage } from "../services/pubsub.js";
import { downloadOriginal, uploadThumbnail } from "../services/storage.js";
import { writePhotoMetadata } from "../services/firestore.js";
import { publishProcessingComplete } from "../services/pubsub.js";
import { computeContentHash } from "./hash.js";
import { extractExif } from "./exif.js";
import { generateBlurHash } from "./blurhash.js";
import { generateThumbnails } from "./thumbnails.js";
import { logger } from "../utils/logger.js";

/**
 * Run the full image processing pipeline for a single photo.
 *
 * Steps:
 *   1. Download original from user's GCS bucket
 *   2. Compute SHA-256 content hash (dedup key)
 *   3. Extract EXIF metadata
 *   4. Generate BlurHash for progressive loading
 *   5. Generate 4 thumbnail variants (sm/md/lg AVIF, xl WebP)
 *   6. Upload thumbnails to GCS at /thumbnails/{hash}_{size}.{ext}
 *   7. Write metadata to Firestore
 *   8. Publish processing-complete event
 */
export async function processPhoto(
  job: ProcessingJobMessage,
): Promise<ProcessingResult> {
  const { userId, bucketName, objectPath, mimeType, fileSizeBytes } = job;

  logger.info("Starting photo processing", { userId, bucketName, objectPath });

  // 1. Download original
  const originalBuffer = await downloadOriginal(bucketName, objectPath);

  // 2. Compute content hash
  const contentHash = computeContentHash(originalBuffer);
  logger.info("Content hash computed", { contentHash });

  // 3 & 4. Run EXIF extraction and BlurHash generation in parallel
  const [exif, blurHash] = await Promise.all([
    extractExif(originalBuffer),
    generateBlurHash(originalBuffer),
  ]);

  logger.info("EXIF and BlurHash extracted", {
    contentHash,
    hasGps: exif.gps !== null,
    width: exif.width,
    height: exif.height,
  });

  // 5. Generate all thumbnail variants
  const thumbnails = await generateThumbnails(originalBuffer);

  logger.info("Thumbnails generated", {
    contentHash,
    variants: thumbnails.map((t) => `${t.size}:${t.format}`),
  });

  // 6. Upload thumbnails to GCS in parallel
  const uploadResults = await Promise.all(
    thumbnails.map((t) =>
      uploadThumbnail(bucketName, contentHash, t.size, t.format, t.buffer),
    ),
  );

  const thumbnailPaths: Record<ThumbnailSize, string> = {
    sm: "",
    md: "",
    lg: "",
    xl: "",
  };
  thumbnails.forEach((t, i) => {
    thumbnailPaths[t.size] = uploadResults[i];
  });

  logger.info("Thumbnails uploaded", { contentHash, thumbnailPaths });

  // 7. Write metadata to Firestore
  const now = new Date().toISOString();
  const metadata: PhotoMetadata = {
    userId,
    contentHash,
    originalPath: objectPath,
    bucketName,
    fileSizeBytes,
    mimeType,
    exif,
    blurHash,
    thumbnails: thumbnailPaths,
    status: "completed",
    processedAt: now,
    createdAt: now,
    updatedAt: now,
  };

  await writePhotoMetadata(metadata);

  // 8. Publish completion event
  await publishProcessingComplete(contentHash, userId, bucketName);

  logger.info("Photo processing complete", { contentHash, userId });

  return {
    contentHash,
    exif,
    blurHash,
    thumbnails,
    thumbnailPaths,
  };
}
