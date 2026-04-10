import { cloudEvent, CloudEvent } from "@google-cloud/functions-framework";
import { PubSub } from "@google-cloud/pubsub";
import { loadConfig } from "./config.js";

// ── Types ──────────────────────────────────────────────────────────────────

/** Payload shape for a GCS object finalize event (CloudEvents v1). */
interface GcsObjectData {
  bucket: string;
  name: string;
  contentType?: string;
  size?: string;
  metageneration?: string;
  metadata?: Record<string, string>;
}

/** Message published to the photo-uploads Pub/Sub topic. */
interface PhotoUploadMessage {
  bucketName: string;
  objectPath: string;
  contentType: string;
  size: number;
  eventTime: string;
  userId: string;
}

// ── Helpers ────────────────────────────────────────────────────────────────

/**
 * Extract the user ID from the GCS object path.
 *
 * Convention: objects are stored at `originals/{userId}/{fileName}`.
 * Falls back to the object-level `userId` custom metadata if set,
 * then to "unknown".
 */
function extractUserId(objectPath: string, metadata?: Record<string, string>): string {
  if (metadata?.userId) {
    return metadata.userId;
  }

  // Object path format: originals/{userId}/{fileName}
  const parts = objectPath.split("/");
  if (parts.length >= 3 && parts[0] === "originals" && parts[1]) {
    return parts[1];
  }

  return "unknown";
}

/** Structured JSON log helper. */
function log(severity: string, message: string, fields?: Record<string, unknown>): void {
  const entry = {
    severity,
    message,
    timestamp: new Date().toISOString(),
    ...fields,
  };
  // Cloud Logging parses structured JSON written to stdout/stderr.
  console.log(JSON.stringify(entry));
}

// ── Cloud Function ─────────────────────────────────────────────────────────

let pubsub: PubSub | undefined;

cloudEvent("eventRouter", async (event: CloudEvent<GcsObjectData>) => {
  const config = loadConfig();

  if (!pubsub) {
    pubsub = new PubSub({ projectId: config.gcpProjectId });
  }

  const data = event.data;
  if (!data) {
    log("WARNING", "Received CloudEvent with no data payload", { eventId: event.id });
    return;
  }

  const { bucket, name: objectPath, contentType, size, metadata } = data;

  // Only process objects under the /originals/ prefix.
  if (!objectPath.startsWith("originals/")) {
    log("DEBUG", "Skipping non-originals object", { bucket, objectPath });
    return;
  }

  const userId = extractUserId(objectPath, metadata);

  const message: PhotoUploadMessage = {
    bucketName: bucket,
    objectPath,
    contentType: contentType ?? "application/octet-stream",
    size: size ? Number(size) : 0,
    eventTime: event.time ?? new Date().toISOString(),
    userId,
  };

  const topic = pubsub.topic(config.pubsubTopic);

  const messageId = await topic.publishMessage({
    json: message,
    attributes: {
      bucketName: bucket,
      userId,
    },
  });

  log("INFO", "Published photo-upload event to Pub/Sub", {
    messageId,
    bucket,
    objectPath,
    userId,
    topic: config.pubsubTopic,
  });
});
