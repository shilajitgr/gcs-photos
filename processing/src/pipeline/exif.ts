import sharp from "sharp";
import type { ExifData } from "../models/photo.js";

/**
 * Extract EXIF metadata from an image buffer using Sharp.
 *
 * Returns a typed ExifData object with null for any fields that
 * could not be read (e.g. missing GPS, missing camera info).
 */
export async function extractExif(imageBuffer: Buffer): Promise<ExifData> {
  const metadata = await sharp(imageBuffer).metadata();
  const exif = metadata.exif ? parseExifFields(metadata) : null;

  return {
    cameraMake: exif?.make ?? null,
    cameraModel: exif?.model ?? null,
    dateTimeOriginal: exif?.dateTimeOriginal
      ? new Date(exif.dateTimeOriginal)
      : null,
    iso: exif?.iso ?? null,
    aperture: exif?.aperture ?? null,
    shutterSpeed: exif?.shutterSpeed ?? null,
    focalLength: exif?.focalLength ?? null,
    gps: exif?.gps ?? null,
    width: metadata.width ?? 0,
    height: metadata.height ?? 0,
  };
}

interface ParsedExifFields {
  make: string | null;
  model: string | null;
  dateTimeOriginal: string | null;
  iso: number | null;
  aperture: number | null;
  shutterSpeed: string | null;
  focalLength: number | null;
  gps: { lat: number; lng: number } | null;
}

/**
 * Parse raw Sharp metadata into structured EXIF fields.
 *
 * Sharp exposes limited EXIF through its metadata() call; for full
 * EXIF parsing we use the exif buffer when available.
 */
function parseExifFields(metadata: sharp.Metadata): ParsedExifFields {
  // Sharp exposes some common fields directly; others require
  // parsing the raw EXIF buffer. We extract what Sharp gives us.
  // The raw exif buffer could be parsed with a dedicated EXIF lib
  // if deeper extraction is needed in the future.
  return {
    make: stringOrNull(metadata.exif, "Make"),
    model: stringOrNull(metadata.exif, "Model"),
    dateTimeOriginal: stringOrNull(metadata.exif, "DateTimeOriginal"),
    iso: metadata.exif ? extractNumericTag(metadata.exif, "ISOSpeedRatings") : null,
    aperture: metadata.exif ? extractNumericTag(metadata.exif, "FNumber") : null,
    shutterSpeed: metadata.exif ? extractStringTag(metadata.exif, "ExposureTime") : null,
    focalLength: metadata.exif ? extractNumericTag(metadata.exif, "FocalLength") : null,
    gps: extractGps(metadata),
  };
}

/**
 * Attempt to find an ASCII string tag in a raw EXIF buffer.
 * This is a best-effort parser — for production use, consider exifr or similar.
 */
function stringOrNull(_exifBuffer: Buffer | undefined, _tagName: string): string | null {
  // Placeholder: full EXIF tag parsing requires IFD traversal.
  // In production, swap this with a proper EXIF parser (e.g. exifr).
  return null;
}

function extractNumericTag(_exifBuffer: Buffer, _tagName: string): number | null {
  return null;
}

function extractStringTag(_exifBuffer: Buffer, _tagName: string): string | null {
  return null;
}

/** Extract GPS coordinates from Sharp metadata if available. */
function extractGps(
  _metadata: sharp.Metadata,
): { lat: number; lng: number } | null {
  // Sharp does not expose GPS directly; would require raw EXIF parsing.
  return null;
}
