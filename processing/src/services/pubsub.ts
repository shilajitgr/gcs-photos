import { PubSub } from "@google-cloud/pubsub";
import { loadConfig } from "../config/index.js";
import { logger } from "../utils/logger.js";

let client: PubSub | null = null;

function getPubSub(): PubSub {
  if (!client) {
    const config = loadConfig();
    client = new PubSub({ projectId: config.gcpProjectId });
  }
  return client;
}

/** Shape of an inbound processing job message. */
export interface ProcessingJobMessage {
  /** User UID. */
  userId: string;
  /** GCS bucket containing the original. */
  bucketName: string;
  /** GCS object path (e.g. originals/abc123.jpg). */
  objectPath: string;
  /** Original MIME type. */
  mimeType: string;
  /** Original file size in bytes. */
  fileSizeBytes: number;
}

/**
 * Parse a Pub/Sub message body into a typed processing job.
 */
export function parseJobMessage(data: string): ProcessingJobMessage {
  const parsed: unknown = JSON.parse(data);

  if (
    typeof parsed !== "object" ||
    parsed === null ||
    !("userId" in parsed) ||
    !("bucketName" in parsed) ||
    !("objectPath" in parsed)
  ) {
    throw new Error("Invalid processing job message: missing required fields");
  }

  const msg = parsed as Record<string, unknown>;

  return {
    userId: String(msg.userId),
    bucketName: String(msg.bucketName),
    objectPath: String(msg.objectPath),
    mimeType: typeof msg.mimeType === "string" ? msg.mimeType : "image/jpeg",
    fileSizeBytes: Number(msg.fileSizeBytes ?? 0),
  };
}

/**
 * Publish a processing-complete event to the configured Pub/Sub topic.
 */
export async function publishProcessingComplete(
  contentHash: string,
  userId: string,
  bucketName: string,
): Promise<string> {
  const config = loadConfig();
  const pubsub = getPubSub();

  const messageId = await pubsub
    .topic(config.pubsubTopic)
    .publishMessage({
      json: {
        event: "processing.complete",
        contentHash,
        userId,
        bucketName,
        timestamp: new Date().toISOString(),
      },
    });

  logger.info("Published processing.complete event", {
    messageId,
    contentHash,
    userId,
  });

  return messageId;
}
