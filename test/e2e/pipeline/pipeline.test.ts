/**
 * E2E tests for the CGS Photos processing pipeline.
 *
 * These tests verify the end-to-end flow:
 *   Upload to GCS -> Pub/Sub event -> Processing job -> Thumbnails + metadata in Firestore
 *
 * Requires emulators to be running (see docker-compose.test.yml).
 */

const PUBSUB_EMULATOR_HOST = process.env.PUBSUB_EMULATOR_HOST || "localhost:8085";
const FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "localhost:8086";
const STORAGE_EMULATOR_HOST = process.env.STORAGE_EMULATOR_HOST || "http://localhost:4443";

describe("Processing Pipeline E2E", () => {
  beforeAll(() => {
    // Ensure emulator environment variables are set for any SDK clients
    process.env.PUBSUB_EMULATOR_HOST = PUBSUB_EMULATOR_HOST;
    process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;
    process.env.STORAGE_EMULATOR_HOST = STORAGE_EMULATOR_HOST;
  });

  it("should have emulators reachable", async () => {
    // Smoke test: verify that the Pub/Sub emulator is reachable
    const resp = await fetch(`http://${PUBSUB_EMULATOR_HOST}/v1/projects/cgs-photos-test/topics`);
    expect(resp.status).toBe(200);
  });

  it.todo("should process an uploaded JPEG and generate thumbnails");

  it.todo("should write photo metadata to Firestore after processing");

  it.todo("should handle duplicate uploads via content-hash dedup");
});
