# ADR-009: Eventarc + Pub/Sub + Cloud Tasks Event Pipeline

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use four GCP-native services for the event pipeline: Eventarc (routing), Pub/Sub (fan-out), Cloud Tasks (rate-limited work), Cloud Scheduler (periodic sweeps).

## Context
Upload events must trigger parallel processing (thumbnails, metadata, lifecycle). Without a message queue, Cloud Functions directly triggered by uploads creates tight coupling — if processing fails, the event is lost.

## Architecture
| Service | Role |
|---------|------|
| **Eventarc** | Routes GCS upload events and Firestore change events to Pub/Sub topics |
| **Cloud Pub/Sub** | Event fan-out hub. Upload event fans out to: thumbnail generation, metadata indexing, lifecycle check — all in parallel |
| **Cloud Tasks** | Rate-limited, retryable task execution. Lifecycle transitions and batch reprocessing use Cloud Tasks to prevent GCS API quota spikes |
| **Cloud Scheduler** | Periodic lifecycle sweeps. Daily/weekly to identify photos eligible for storage class transitions |

## Consequences
- Decoupled ingestion from processing
- At-least-once delivery with dead-letter queues
- Rate limiting on GCS API calls via Cloud Tasks
- Retry isolation — failed thumbnail generation doesn't block metadata indexing
- Cloud Functions Gen 2 retained only for lightweight Eventarc-to-Pub/Sub bridging
