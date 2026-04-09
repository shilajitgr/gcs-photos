/** EXIF metadata extracted from the original image. */
export interface ExifData {
  cameraMake: string | null;
  cameraModel: string | null;
  dateTimeOriginal: Date | null;
  iso: number | null;
  aperture: number | null;
  shutterSpeed: string | null;
  focalLength: number | null;
  gps: { lat: number; lng: number } | null;
  width: number;
  height: number;
}

/** Thumbnail size variants. */
export type ThumbnailSize = "sm" | "md" | "lg" | "xl";

/** Output format for a generated thumbnail. */
export type ThumbnailFormat = "avif" | "webp";

/** Result of generating a single thumbnail variant. */
export interface ThumbnailResult {
  size: ThumbnailSize;
  format: ThumbnailFormat;
  width: number;
  buffer: Buffer;
  /** SHA-256 hex digest of the thumbnail buffer. */
  hash: string;
}

/** Dimensions (in pixels) for each thumbnail variant. */
export const THUMBNAIL_DIMENSIONS: Record<ThumbnailSize, number> = {
  sm: 200,
  md: 600,
  lg: 1200,
  xl: 1200,
};

/** Output format for each thumbnail variant. */
export const THUMBNAIL_FORMATS: Record<ThumbnailSize, ThumbnailFormat> = {
  sm: "avif",
  md: "avif",
  lg: "avif",
  xl: "webp",
};

/** Full metadata written to Firestore after processing an image. */
export interface PhotoMetadata {
  /** User UID owning this photo. */
  userId: string;
  /** SHA-256 hex digest of the original file. */
  contentHash: string;
  /** GCS object path of the original (e.g. originals/abc123.jpg). */
  originalPath: string;
  /** GCS bucket name (user-owned). */
  bucketName: string;
  /** Original file size in bytes. */
  fileSizeBytes: number;
  /** Original MIME type. */
  mimeType: string;
  /** Extracted EXIF metadata. */
  exif: ExifData;
  /** BlurHash string for progressive loading. */
  blurHash: string;
  /** Map of thumbnail size to GCS path. */
  thumbnails: Record<ThumbnailSize, string>;
  /** Processing status. */
  status: "pending" | "processing" | "completed" | "failed";
  /** ISO-8601 timestamp when processing completed. */
  processedAt: string;
  /** ISO-8601 timestamp when the photo was uploaded. */
  createdAt: string;
  /** ISO-8601 timestamp of the last metadata update. */
  updatedAt: string;
}

/** The aggregate result returned by the processing pipeline. */
export interface ProcessingResult {
  contentHash: string;
  exif: ExifData;
  blurHash: string;
  thumbnails: ThumbnailResult[];
  /** GCS paths where thumbnails were uploaded. */
  thumbnailPaths: Record<ThumbnailSize, string>;
}
