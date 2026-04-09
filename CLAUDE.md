# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CGS Photos is a **Bring Your Own Storage (BYOS) Photo Manager** — a GCP-native platform where users bring their own Google Cloud Storage bucket for photo backup and management. The platform handles compute, metadata, and image processing while users own their storage.

**Status:** Architecture finalized (see `ARCHITECTURE_REVIEW.md`), pre-implementation.

## Architecture

### GCP-Native Stack (Single Vendor)

- **API Layer:** Cloud Run Services — auth, metadata CRUD, upload URL generation, lifecycle config
- **Image Processing:** Cloud Run Jobs — AVIF encoding, multi-size thumbnail generation, EXIF parsing (24h timeout, custom Docker with libavif/sharp)
- **Image Proxy:** Cloud Run Services behind Cloud CDN — on-demand resize for cache-miss fallback
- **Event Glue:** Cloud Functions Gen 2 — lightweight Eventarc-to-Pub/Sub bridging only
- **Event Pipeline:** Eventarc (routing) → Pub/Sub (fan-out) → Cloud Tasks (rate-limited work) + Cloud Scheduler (periodic sweeps)
- **Metadata:** Firestore — sharded documents, batched writes via Pub/Sub pipeline (not direct writes)
- **Storage:** User's own GCS bucket (`/originals/`, `/thumbnails/`, lifecycle-tiered)
- **Auth:** Firebase Auth (user identity) + Workload Identity Federation (key-less, scoped GCS bucket access)
- **Edge:** Cloud CDN + Global External ALB + Cloud Armor Standard (WAF/DDoS)
- **Observability:** Cloud Logging, Cloud Trace, Error Reporting, Cloud Monitoring (SLOs + alerts)

### Mobile Client (Flutter)

- **Local DB:** SQLite via Drift (type-safe Dart SQL, formerly Moor) with SQLCipher encryption
- **Sync:** Full sync via paginated Cloud Run API on fresh login; real-time Firestore `onSnapshot` incremental sync thereafter
- **Caching:** LRU thumbnail cache in SQLite (500MB max), BlurHash for instant progressive loading
- **Dedup:** Two-layer — SHA-256 content hash (exact match, streaming, no full file in memory) + EXIF composite key (fuzzy/near-duplicate detection)

### Key Design Decisions

- **Content-hash-based thumbnail URLs** (`/thumb/{hash}_{size}.avif`) — makes CDN cache invalidation unnecessary
- **Firestore writes are batched via Pub/Sub pipeline** — never write metadata directly from the upload path (10K writes/sec DB limit, 1 write/sec per doc)
- **Conflict resolution:** Last-write-wins with device vector clock for detection
- **Thumbnail variants:** `thumb_sm` (200px AVIF), `thumb_md` (600px AVIF), `thumb_lg` (1200px AVIF), `thumb_xl` (1200px WebP fallback)
- **SQLite is the dedup authority** after initial sync — no per-photo Firestore queries during device scan

### Processing Flow

```
Upload → Eventarc → Pub/Sub fan-out →
  1. Cloud Run Jobs (AVIF encoding, multi-size thumbnails, EXIF parsing)
  2. Batched metadata write to Firestore
  3. Cloud Tasks for lifecycle transitions (rate-limited)
```

## Local Database Schema

Three tables in SQLite/Drift: `photos` (core metadata + EXIF + sync state + dedup fields), `thumbnail_cache` (LRU-evicted blobs), `sync_state` (Firestore resume tokens). See `ARCHITECTURE_REVIEW.md` Section 6.1 for full DDL.
