# ADR-010: Split Compute Model (Cloud Run Services + Jobs + Functions)

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Split compute across three GCP services based on workload characteristics.

## Context
Different workloads have different requirements: API needs concurrency, image processing needs long timeouts and custom containers, event routing needs minimal overhead.

## Compute Split
| Workload | Service | Rationale |
|----------|---------|-----------|
| API layer (auth, metadata CRUD, upload URL generation) | **Cloud Run Services** | Per-instance concurrency up to 1000. Native Cloud CDN integration. |
| Heavy image processing (AVIF encoding, batch thumbnails) | **Cloud Run Jobs** | 24-hour timeout. Full container support for optimized libavif/sharp Docker builds. |
| On-demand image resize (cache-miss fallback) | **Cloud Run Services** (image proxy) | Lightweight service behind Cloud CDN. Result cached at edge. |
| Lightweight event glue (Eventarc→Pub/Sub) | **Cloud Functions Gen 2** | Simple event routing. No container overhead needed. |

## Why Not Cloud Functions for Everything?
- Cloud Functions Gen 2 caps at 8 vCPU / 32GB RAM / 60-minute timeout
- AVIF encoding of large albums (1000+ photos) hits these limits
- Cloud Run Jobs: 24-hour timeout, full container control

## Why Not GKE?
- GKE Autopilot has minimum 1 node (always-on cost)
- Not justified at MVP scale
- Revisit if GPU-based processing (AI tagging) is added later

## Consequences
- All serverless, all scale to zero
- Per-task billing on Cloud Run Jobs
- Full Docker container control for image processing (libavif, sharp, custom binaries)
