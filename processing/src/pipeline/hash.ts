import { createHash } from "node:crypto";

/**
 * Compute the SHA-256 hex digest of a buffer.
 *
 * This is the content-addressable hash used for deduplication and
 * for building thumbnail URLs (e.g. /thumb/{hash}_{size}.avif).
 */
export function computeContentHash(buffer: Buffer): string {
  return createHash("sha256").update(buffer).digest("hex");
}
