import { cloudEvent, CloudEvent } from "@google-cloud/functions-framework";
import { v2 } from "@google-cloud/run";

const jobsClient = new v2.JobsClient();

interface PubSubMessageData {
  bucketName?: string;
  objectPath?: string;
  contentType?: string;
  size?: number;
  userId?: string;
}

interface CloudEventData {
  message?: {
    data?: string;
    attributes?: Record<string, string>;
  };
}

const PROJECT_ID = process.env.GCP_PROJECT_ID || "";
const REGION = process.env.GCP_REGION || "asia-south1";
const JOB_NAME = process.env.PROCESSING_JOB_NAME || "cgs-processing";

/**
 * Cloud Function that receives photo-upload Pub/Sub messages and
 * triggers a Cloud Run Job execution for each photo.
 */
cloudEvent("processingTrigger", async (event: CloudEvent<CloudEventData>) => {
  const base64Data = event.data?.message?.data;
  if (!base64Data) {
    console.error("No message data in event");
    return;
  }

  const raw = Buffer.from(base64Data, "base64").toString("utf-8");
  let msg: PubSubMessageData;
  try {
    msg = JSON.parse(raw) as PubSubMessageData;
  } catch {
    console.error("Failed to parse message JSON:", raw);
    return;
  }

  if (!msg.bucketName || !msg.objectPath) {
    console.error("Missing required fields in message:", msg);
    return;
  }

  // Map eventrouter message fields to processing job fields
  const jobPayload = JSON.stringify({
    userId: msg.userId || "unknown",
    bucketName: msg.bucketName,
    objectPath: msg.objectPath,
    mimeType: msg.contentType || "image/jpeg",
    fileSizeBytes: msg.size || 0,
  });

  const jobPath = `projects/${PROJECT_ID}/locations/${REGION}/jobs/${JOB_NAME}`;

  console.log(JSON.stringify({
    severity: "INFO",
    message: "Triggering processing job",
    objectPath: msg.objectPath,
    bucketName: msg.bucketName,
  }));

  try {
    const [operation] = await jobsClient.runJob({
      name: jobPath,
      overrides: {
        containerOverrides: [
          {
            env: [
              { name: "PROCESSING_JOB", value: Buffer.from(jobPayload).toString("base64") },
            ],
          },
        ],
        taskCount: 1,
      },
    });

    console.log(JSON.stringify({
      severity: "INFO",
      message: "Processing job triggered",
      operation: operation.name,
      objectPath: msg.objectPath,
    }));
  } catch (err) {
    console.error(JSON.stringify({
      severity: "ERROR",
      message: "Failed to trigger processing job",
      error: err instanceof Error ? err.message : String(err),
      objectPath: msg.objectPath,
    }));
    throw err;
  }
});
