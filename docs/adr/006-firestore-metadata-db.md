# ADR-006: Firestore for Metadata Database

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Firestore as the primary metadata database with batched writes via Pub/Sub pipeline.

## Context
The platform needs a metadata store for EXIF data, file paths, storage class state, BlurHashes, and thumbnail URL hashes. Must support real-time sync to mobile clients and offline access.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Cloud Spanner | Virtually unlimited writes but $50+/day — overkill for MVP |
| Cloud SQL (PostgreSQL) | Full SQL + JSONB but no native real-time sync or offline support |
| Bigtable | Millions of writes/sec but no secondary indexes, no real-time sync |
| MongoDB Atlas | Good alternative but non-GCP, violates single-vendor constraint |

## Key Constraints
- Firestore: 10K writes/sec per DB, 1 write/sec per document
- Mitigated by: batched writes via Pub/Sub → Cloud Run pipeline (never direct from upload path)
- Sharded hot documents using `shardId` field (e.g., `userId_shardN`)

## Consequences
- Native `onSnapshot` real-time sync for multi-device galleries
- Native offline SDK for intermittent connectivity
- Serverless pricing that scales to zero
- ~$1.80/day for 1M reads + 500K writes
- If EXIF search grows complex: add Cloud SQL (PostgreSQL) as secondary search index
- Subcollections keyed by date range to avoid read contention hotspots
