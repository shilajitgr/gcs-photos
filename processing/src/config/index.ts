/** Processing pipeline configuration loaded from environment variables. */
export interface Config {
  gcpProjectId: string;
  storageBucket: string;
  firestoreDatabase: string;
  pubsubTopic: string;
  pubsubSubscription: string;
  /** Cloud Run Jobs task index (0-based). */
  taskIndex: number;
  /** Cloud Run Jobs total task count. */
  taskCount: number;
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optionalEnv(name: string, fallback: string): string {
  return process.env[name] ?? fallback;
}

/** Load configuration from environment variables. */
export function loadConfig(): Config {
  return {
    gcpProjectId: requireEnv("GCP_PROJECT_ID"),
    storageBucket: requireEnv("STORAGE_BUCKET"),
    firestoreDatabase: optionalEnv("FIRESTORE_DATABASE", "(default)"),
    pubsubTopic: requireEnv("PUBSUB_TOPIC"),
    pubsubSubscription: requireEnv("PUBSUB_SUBSCRIPTION"),
    taskIndex: parseInt(optionalEnv("CLOUD_RUN_TASK_INDEX", "0"), 10),
    taskCount: parseInt(optionalEnv("CLOUD_RUN_TASK_COUNT", "1"), 10),
  };
}
