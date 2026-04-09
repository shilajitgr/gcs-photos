# ADR-007: SQLite via Drift for Mobile Local Database

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use SQLite via Drift (formerly Moor) as the mobile local database with SQLCipher for encryption at rest.

## Context
The mobile client needs a local database for: offline metadata access, EXIF querying, thumbnail caching (LRU), and dedup authority after sync.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Realm (MongoDB) | Built-in sync but targets MongoDB Atlas, not Firestore — violates single-vendor |
| Hive (Dart) | Key-value only, limited querying, RAM-bound on open |
| ObjectBox | Good performance but sync is paid; no SQL |
| Isar | Good but less mature than SQLite ecosystem |

## Consequences
- Full SQL for complex local EXIF queries (e.g., "photos in January with ISO > 800")
- Battle-tested (20+ years, most deployed DB engine)
- Drift provides type-safe Dart queries, automatic schema migrations, reactive streams
- SQLCipher extension: AES-256 encryption at rest for cached metadata
- Sync with Firestore is manual: `onSnapshot` listeners stream changes into local SQLite
- Three tables: `photos`, `thumbnail_cache`, `sync_state`
- SQLite is the dedup authority after initial sync — no per-photo Firestore queries during device scan
- LRU thumbnail cache: 500MB max, evict at 90%, target 70%
