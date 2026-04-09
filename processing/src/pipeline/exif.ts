import exifr from "exifr";
import sharp from "sharp";
import type { ExifData } from "../models/photo.js";

/**
 * Extract EXIF metadata from an image buffer using exifr (full EXIF/IPTC/XMP parsing)
 * with Sharp as fallback for width/height.
 */
export async function extractExif(imageBuffer: Buffer): Promise<ExifData> {
  const metadata = await sharp(imageBuffer).metadata();

  let parsed: Record<string, unknown> | null = null;
  try {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    parsed = await exifr.parse(imageBuffer, {
      tiff: true,
      exif: true,
      gps: true,
      iptc: false,
      xmp: false,
      pick: [
        "Make",
        "Model",
        "DateTimeOriginal",
        "ISO",
        "FNumber",
        "ExposureTime",
        "FocalLength",
        "GPSLatitude",
        "GPSLongitude",
        "GPSLatitudeRef",
        "GPSLongitudeRef",
      ],
    });
  } catch {
    // Image may not contain EXIF data — that's fine
    parsed = null;
  }

  const gpsLat = parsed?.latitude as number | undefined;
  const gpsLng = parsed?.longitude as number | undefined;

  return {
    cameraMake: asStringOrNull(parsed?.Make),
    cameraModel: asStringOrNull(parsed?.Model),
    dateTimeOriginal: parsed?.DateTimeOriginal instanceof Date
      ? parsed.DateTimeOriginal
      : parsed?.DateTimeOriginal != null
        ? new Date(typeof parsed.DateTimeOriginal === "string" ? parsed.DateTimeOriginal : "")
        : null,
    iso: asNumberOrNull(parsed?.ISO),
    aperture: asNumberOrNull(parsed?.FNumber),
    shutterSpeed: parsed?.ExposureTime != null
      ? (typeof parsed.ExposureTime === "string" ? parsed.ExposureTime : `${parsed.ExposureTime as number}`)
      : null,
    focalLength: asNumberOrNull(parsed?.FocalLength),
    gps:
      gpsLat != null && gpsLng != null && isFinite(gpsLat) && isFinite(gpsLng)
        ? { lat: gpsLat, lng: gpsLng }
        : null,
    width: metadata.width ?? 0,
    height: metadata.height ?? 0,
  };
}

function asStringOrNull(val: unknown): string | null {
  if (typeof val === "string" && val.length > 0) return val;
  return null;
}

function asNumberOrNull(val: unknown): number | null {
  if (typeof val === "number" && isFinite(val)) return val;
  return null;
}
