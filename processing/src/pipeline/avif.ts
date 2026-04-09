import sharp from "sharp";

/**
 * Encode an image buffer to AVIF at the given width.
 *
 * Uses Sharp's built-in AVIF encoder (based on libvips/libheif).
 * Quality is tuned for thumbnail use: visually good at small sizes
 * while keeping file size low.
 */
export async function encodeAvif(
  buffer: Buffer,
  width: number,
  quality = 50,
): Promise<Buffer> {
  return sharp(buffer)
    .resize(width, undefined, {
      fit: "inside",
      withoutEnlargement: true,
    })
    .avif({
      quality,
      effort: 4, // 0-9; 4 is a good speed/quality trade-off
    })
    .toBuffer();
}
