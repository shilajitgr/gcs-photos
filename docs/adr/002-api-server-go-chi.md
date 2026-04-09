# ADR-002: Go + Chi for API Server

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Go with the Chi router (go-chi/chi) for the Cloud Run API server.

## Context
The API layer handles auth, metadata CRUD, upload URL generation, and lifecycle config. It runs on Cloud Run behind a Global External ALB + Cloud Armor.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Node.js (TypeScript) | Rich GCP/Firebase SDK but higher cold starts and memory |
| Python (FastAPI) | Good for prototyping but highest cold start and memory on Cloud Run |
| Dart (Shelf/Serverpod) | Shared language with Flutter but smaller ecosystem, less battle-tested on Cloud Run |

### Chi vs Alternatives
| Option | Verdict |
|--------|---------|
| Gin | Most popular but slightly less idiomatic than Chi |
| Standard library (net/http) | Zero deps but more boilerplate |
| Fiber | Express-inspired, fast, but not stdlib-compatible |

## Consequences
- Fast cold starts (~100ms) on Cloud Run
- Low memory footprint (~20-30MB base)
- Excellent goroutine-based concurrency for parallel Firestore/GCS/Pub/Sub calls
- Chi is stdlib-compatible — middleware from the Go ecosystem works without adapters
- Go's Firebase Admin SDK, Firestore, GCS, and Pub/Sub clients are all officially supported
