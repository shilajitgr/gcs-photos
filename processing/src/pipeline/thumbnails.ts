import sharp from "sharp";
import { computeContentHash } from "./hash.js";
import type { ThumbnailResult, ThumbnailSize, ThumbnailFormat } from "../models/photo.js";
import { THUMBNAIL_DIMENSIONS, THUMBNAIL_FORMATS } from "../models/photo.js";

/** Quality setting for AVIF thumbnail variants. */
const AVIF_QUALITY = 50;
/** Quality setting for WebP fallback variant. */
const WEBP_QUALITY = 75;

/**
 * Generate all 4 thumbnail variants from an original image buffer.
 *
 * Variants:
 *   thumb_sm  — 200px  AVIF
 *   thumb_md  — 600px  AVIF
 *   thumb_lg  — 1200px AVIF
 *   thumb_xl  — 1200px WebP (fallback for clients without AVIF)
 *
 * Each thumbnail is resized to fit within the target width (maintaining
 * aspect ratio, never enlarging) and encoded in the appropriate format.
 */
export async function generateThumbnails(
  imageBuffer: Buffer,
): Promise<ThumbnailResult[]> {
  const sizes: ThumbnailSize[] = ["sm", "md", "lg", "xl"];

  const results = await Promise.all(
    sizes.map((size) => generateSingleThumbnail(imageBuffer, size)),
  );

  return results;
}

async function generateSingleThumbnail(
  imageBuffer: Buffer,
  size: ThumbnailSize,
): Promise<ThumbnailResult> {
  const width = THUMBNAIL_DIMENSIONS[size];
  const format: ThumbnailFormat = THUMBNAIL_FORMATS[size];

  let pipeline = sharp(imageBuffer).resize(width, undefined, {
    fit: "inside",
    withoutEnlargement: true,
  });

  if (format === "avif") {
    pipeline = pipeline.avif({ quality: AVIF_QUALITY, effort: 4 });
  } else {
    pipeline = pipeline.webp({ quality: WEBP_QUALITY });
  }

  const buffer = await pipeline.toBuffer();
  const hash = computeContentHash(buffer);

  // Read back the actual width after resize (may differ if original was smaller)
  const info = await sharp(buffer).metadata();

  return {
    size,
    format,
    width: info.width ?? width,
    buffer,
    hash,
  };
}
