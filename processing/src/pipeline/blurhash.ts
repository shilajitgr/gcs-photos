import sharp from "sharp";
import { encode } from "blurhash";

/** Width used when computing BlurHash (small for speed). */
const BLURHASH_WIDTH = 32;

/**
 * Generate a BlurHash string from an image buffer.
 *
 * The image is first resized to a tiny thumbnail (32px wide) so
 * the BlurHash computation is fast regardless of original size.
 * BlurHash is used on the client for instant progressive loading.
 */
export async function generateBlurHash(imageBuffer: Buffer): Promise<string> {
  const { data, info } = await sharp(imageBuffer)
    .resize(BLURHASH_WIDTH, undefined, {
      fit: "inside",
      withoutEnlargement: true,
    })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  // blurhash encode expects Uint8ClampedArray of RGBA pixels
  const pixels = new Uint8ClampedArray(data.buffer, data.byteOffset, data.byteLength);

  // Component counts — 4x3 gives a good balance of detail vs. string length
  const componentX = 4;
  const componentY = 3;

  return encode(pixels, info.width, info.height, componentX, componentY);
}
