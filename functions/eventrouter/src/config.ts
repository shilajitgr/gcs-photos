/**
 * Configuration for the Event Router Cloud Function.
 *
 * All values are read from environment variables with sensible defaults
 * for local development.
 */

export interface Config {
  /** GCP project ID (required in production). */
  gcpProjectId: string;

  /** Pub/Sub topic to publish photo-upload messages to. */
  pubsubTopic: string;
}

export function loadConfig(): Config {
  const gcpProjectId = process.env.GCP_PROJECT_ID ?? process.env.GCLOUD_PROJECT ?? "";
  if (!gcpProjectId) {
    throw new Error(
      "GCP_PROJECT_ID environment variable is required. " +
        "Set it or ensure GCLOUD_PROJECT is available.",
    );
  }

  return {
    gcpProjectId,
    pubsubTopic: process.env.PUBSUB_TOPIC ?? "photo-uploads",
  };
}
