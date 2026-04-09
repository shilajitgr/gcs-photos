import { loadConfig } from "./config/index.js";
import { processPhoto } from "./pipeline/processor.js";
import { parseJobMessage } from "./services/pubsub.js";
import { logger } from "./utils/logger.js";

/**
 * Cloud Run Jobs entrypoint for the CGS Photos image processing pipeline.
 *
 * Reads job parameters from the PROCESSING_JOB environment variable
 * (a JSON-encoded Pub/Sub message body). Cloud Run Jobs parallelism
 * is supported via CLOUD_RUN_TASK_INDEX and CLOUD_RUN_TASK_COUNT.
 */
async function main(): Promise<void> {
  const config = loadConfig();

  logger.info("Processing job starting", {
    taskIndex: config.taskIndex,
    taskCount: config.taskCount,
    projectId: config.gcpProjectId,
  });

  // The job payload is passed as a base64-encoded or raw JSON env var
  const jobData = process.env.PROCESSING_JOB;
  if (!jobData) {
    throw new Error(
      "Missing PROCESSING_JOB environment variable. " +
        "Expected a JSON-encoded processing job message.",
    );
  }

  // Decode base64 if needed (Cloud Run Jobs may pass base64 Pub/Sub data)
  let decoded: string;
  try {
    decoded = Buffer.from(jobData, "base64").toString("utf-8");
    // Validate it's actually JSON
    JSON.parse(decoded);
  } catch {
    // Not base64; treat as raw JSON
    decoded = jobData;
  }

  const job = parseJobMessage(decoded);

  logger.info("Job parsed", {
    userId: job.userId,
    bucketName: job.bucketName,
    objectPath: job.objectPath,
    taskIndex: config.taskIndex,
  });

  const result = await processPhoto(job);

  logger.info("Processing complete", {
    contentHash: result.contentHash,
    thumbnailCount: result.thumbnails.length,
    taskIndex: config.taskIndex,
  });
}

main().catch((err: unknown) => {
  const errorMessage =
    err instanceof Error ? err.message : String(err);
  const errorStack =
    err instanceof Error ? err.stack : undefined;

  logger.critical("Processing job failed", {
    error: errorMessage,
    stack: errorStack,
  });

  process.exit(1);
});
