import { Firestore } from "@google-cloud/firestore";
import type { PhotoMetadata } from "../models/photo.js";
import { loadConfig } from "../config/index.js";
import { logger } from "../utils/logger.js";

let db: Firestore | null = null;

function getFirestore(): Firestore {
  if (!db) {
    const config = loadConfig();
    db = new Firestore({
      projectId: config.gcpProjectId,
      databaseId: config.firestoreDatabase,
    });
  }
  return db;
}

/** Firestore collection where processed photo metadata is stored. */
const PHOTOS_COLLECTION = "photos";

/**
 * Write a single photo's processed metadata to Firestore.
 *
 * The document ID is the content hash, which guarantees dedup at
 * the storage layer.
 */
export async function writePhotoMetadata(
  metadata: PhotoMetadata,
): Promise<void> {
  const firestore = getFirestore();

  logger.info("Writing photo metadata to Firestore", {
    contentHash: metadata.contentHash,
    userId: metadata.userId,
  });

  await firestore
    .collection(PHOTOS_COLLECTION)
    .doc(metadata.contentHash)
    .set({
      ...metadata,
      updatedAt: new Date().toISOString(),
    });
}

/**
 * Batch-write multiple photo metadata documents to Firestore.
 *
 * Firestore batches are limited to 500 operations; this function
 * automatically chunks larger sets.
 */
export async function batchWriteMetadata(
  items: PhotoMetadata[],
): Promise<void> {
  const firestore = getFirestore();
  const BATCH_LIMIT = 500;

  for (let i = 0; i < items.length; i += BATCH_LIMIT) {
    const chunk = items.slice(i, i + BATCH_LIMIT);
    const batch = firestore.batch();

    for (const metadata of chunk) {
      const ref = firestore
        .collection(PHOTOS_COLLECTION)
        .doc(metadata.contentHash);

      batch.set(ref, {
        ...metadata,
        updatedAt: new Date().toISOString(),
      });
    }

    await batch.commit();

    logger.info("Batch write committed", {
      count: chunk.length,
      offset: i,
      total: items.length,
    });
  }
}
