# Architecture Review: BYOS Photo Manager

**Reviewer Role:** Senior Architect (High-Concurrency & Cloud Systems)
**Review Date:** 2026-04-09
**BRD Version:** 1.0
**Status:** Review Complete — GCP-Native Stack (Finalized)

---

## Table of Contents

1. [Architecture Assessment](#1-architecture-assessment)
2. [Concerns & Gaps](#2-concerns--gaps)
3. [Service Comparison Charts](#3-service-comparison-charts)
   - [3.1 Object Storage](#31-object-storage-users-primary-storage)
   - [3.2 Metadata Database](#32-metadata-database)
   - [3.3 CDN / Edge Caching](#33-cdn--edge-caching)
   - [3.4 Compute](#34-compute-image-processing--api)
   - [3.5 Event / Message Queue](#35-event--message-queue)
   - [3.6 Auth / Identity Federation](#36-auth--identity-federation)
   - [3.7 Security / WAF / DDoS](#37-security--waf--ddos)
   - [3.8 Image Processing Pipeline](#38-image-processing-pipeline)
   - [3.9 Mobile Local Database](#39-mobile-local-database)
   - [3.10 Image Deduplication / Unique Identifier](#310-image-deduplication--unique-identifier)
4. [Final GCP-Native Architecture](#4-final-gcp-native-architecture)
5. [GCP-Native Service Map](#5-gcp-native-service-map)
6. [Mobile Client Data Strategy](#6-mobile-client-data-strategy)
7. [Cost Projection](#7-cost-projection)
8. [Summary of Changes from Original BRD](#8-summary-of-changes-from-original-brd)
9. [Tradeoffs Accepted](#9-tradeoffs-accepted)

---

## 1. Architecture Assessment

### Strengths (Original BRD)

- **BYOS model is architecturally sound.** Offloading primary storage costs to the user while retaining control over compute and metadata is the correct economic split for this product category.
- **Dual-stage compression** (client-side WebP, server-side AVIF) is a strong design choice. Upload bandwidth and serving bandwidth are reduced independently, and neither stage blocks the other.
- **BlurHash-first loading** is the correct progressive enhancement pattern for low-bandwidth (3G/4G) environments. It avoids layout shift and provides instant perceived responsiveness.
- **Lifecycle tiering** (Standard to Nearline to Archive) directly maps to real-world photo access patterns. Most photos are accessed within weeks of capture and rarely after several months.
- **Workload Identity Federation** eliminates the need to store permanent service account keys, which is the right security posture for a multi-tenant system accessing user-owned buckets.
- **Resumable uploads** are essential given the target audience (intermittent connectivity). GCS native resumable upload support aligns well here.

---

## 2. Concerns & Gaps

| # | Concern | Severity | Impact | Recommendation |
|---|---------|----------|--------|----------------|
| 1 | **Firestore write throughput bottleneck.** Firestore enforces a hard limit of 10,000 writes/sec per database and 1 write/sec per document. A user uploading 500 photos in a burst will serialize on metadata writes and create contention. | **High** | Blocks concurrency at scale | Batch metadata writes via a Pub/Sub pipeline instead of writing directly from the upload path. Shard hot documents using a `shardId` field. |
| 2 | **No message queue between ingestion and processing.** Cloud Functions triggered directly by upload events creates tight coupling. If thumbnail generation fails, the event is lost with no retry isolation or backpressure. | **High** | Silent data loss, no backpressure | Add Pub/Sub between upload events and processing functions. Add Cloud Tasks for rate-limited work. |
| 3 | **Cloud Functions Gen 2 ceiling for image processing.** AVIF encoding is CPU-intensive. Cloud Functions caps at 8 vCPU / 32GB RAM with a 60-minute timeout. Batch processing large albums (1000+ photos) will hit these limits. | **Medium** | Processing ceiling for power users | Use Cloud Run Jobs for heavy image processing. Reserve Cloud Functions for lightweight event glue only. |
| 4 | **No task/job queue for lifecycle orchestration.** Lifecycle transitions across thousands of users need scheduling and rate limiting, not just event triggers. Without a queue, a bulk lifecycle migration can spike GCS API costs. | **Medium** | Uncontrolled API costs, no orchestration | Add Cloud Tasks with rate limiting for lifecycle transitions. Add Cloud Scheduler for periodic sweeps. |
| 5 | **Single-document metadata sync creates a hotspot.** Section 4.1 of the BRD describes fetching metadata via a single synchronized Firestore document. One document receiving concurrent reads from multiple devices will hit Firestore's per-document contention limits. | **Medium** | Degrades multi-device experience | Shard metadata documents or use a read-replica pattern. Consider subcollections keyed by date range. |
| 6 | **No offline/conflict resolution strategy.** Resumable uploads imply intermittent connectivity, but there is no mention of how metadata conflicts are resolved when the same photo is uploaded from two devices simultaneously. | **Medium** | Data integrity risk, duplicate entries | Define a conflict resolution policy. Recommended: last-write-wins with a device vector clock for detection. |
| 7 | **No CDN cache invalidation strategy.** Cloud CDN serves thumbnails, but when a user deletes or re-processes a photo, stale thumbnails persist at the edge until TTL expiry. | **Low** | Stale thumbnails shown after deletion | Use content-hash-based URLs (e.g., `/thumb/{hash}.avif`) so new versions automatically bypass cache. Cloud CDN invalidation takes minutes, so hash-based URLs are essential. |
| 8 | **No observability layer.** No logging, tracing, or alerting strategy is defined for a distributed system with user-owned buckets. Failures in thumbnail generation or lifecycle transitions will be invisible. | **Medium** | Blind to production failures | Add Cloud Logging, Cloud Trace, and Error Reporting. Define SLOs for thumbnail generation latency and upload success rate. |
| 9 | **No WAF/DDoS protection.** The BRD does not mention any perimeter security. A public API serving upload URLs and thumbnails is exposed to abuse. | **Medium** | API abuse, cost spikes from bot traffic | Add Cloud Armor for WAF rules and DDoS protection in front of the Cloud Run API and Cloud CDN. |
| 10 | **No image processing service for on-the-fly transforms.** Since we are staying GCP-native, there is no edge image transformation. All thumbnail sizes and formats must be pre-generated and stored. | **Medium** | Higher storage cost, slower new-format adoption | Pre-generate a defined set of thumbnail sizes via Cloud Run Jobs. Use a Cloud Run service as an image proxy for on-demand resize as a fallback. |

---

## 3. Service Comparison Charts

### 3.1 Object Storage (User's Primary Storage)

Since the BYOS model lets users bring their own bucket, the platform must decide which providers to support.

| Criteria | **GCS (Selected)** | AWS S3 | Azure Blob | Cloudflare R2 |
|----------|---------------------|--------|------------|---------------|
| **Lifecycle Tiering** | Standard, Nearline, Coldline, Archive | Standard, IA, Glacier, Deep Archive | Hot, Cool, Cold, Archive | Single tier (no lifecycle classes) |
| **Resumable Uploads** | Native (tus-compatible) | Multipart Upload API | Block Blob (staged) | S3-compatible multipart |
| **Egress Cost (per GB)** | $0.12 | $0.09 | $0.087 | $0.00 (free) |
| **Storage Cost (Standard, per GB/mo)** | $0.020 | $0.023 | $0.018 | $0.015 |
| **Workload Identity Federation** | Native | IAM Roles Anywhere | Managed Identity / Federated Credentials | API tokens only |
| **CDN Integration** | Cloud CDN (native) | CloudFront (native) | Azure CDN / Front Door | Built-in (automatic) |
| **Event Notifications** | Pub/Sub / Eventarc | S3 Events to SNS/SQS/Lambda | Event Grid | Workers (limited) |
| **Encryption (CMEK)** | Yes (Cloud KMS) | Yes (KMS) | Yes (Key Vault) | No |
| **Global Availability** | Multi-region / Dual-region | Multi-region | GRS / GZRS | Automatic (global) |
| **Ecosystem Maturity** | Strong | Strongest | Strong | Growing |

**Decision:** **GCS**. Native lifecycle tiering is core to the value proposition. Best Workload Identity Federation support. Seamless integration with Cloud CDN, Pub/Sub, and Eventarc. Architect a storage abstraction layer to support AWS S3 in a future phase.

---

### 3.2 Metadata Database

| Criteria | **Firestore (Selected)** | Cloud Spanner | Cloud SQL (PostgreSQL) | Bigtable | MongoDB Atlas (on GCP) |
|----------|--------------------------|---------------|----------------------|----------|----------------------|
| **Data Model** | Document (hierarchical) | Relational (distributed) | Relational | Wide-column | Document (flexible) |
| **Write Throughput** | 10K writes/sec per DB; 1 write/sec per doc | **Virtually unlimited** | ~10K writes/sec (depends on instance) | **Millions of writes/sec** | Virtually unlimited (sharded) |
| **Read Latency (p99)** | <10ms | <10ms (single-region) | <5ms | <10ms | <10ms |
| **Real-time Sync** | **Native (onSnapshot)** | No | No | No | Change Streams |
| **Offline Support** | **Native SDK** | No | No | No | Realm (mobile SDK) |
| **Serverless Pricing** | Per read/write/delete | Per node-hour ($$$) | Per instance-hour | Per node-hour | Per vCPU-hr (serverless) |
| **Cost (1M reads + 500K writes/day)** | ~$1.80/day | ~$50+/day | ~$10-15/day | ~$30+/day | ~$3-5/day |
| **EXIF/JSON Querying** | Composite indexes (limited) | Full SQL | **Full SQL + JSONB** | No secondary indexes | Rich query + aggregation |
| **Multi-tenancy** | Collection-per-user or subcollections | Row-level | Row/schema-level | Row key prefix | Database-per-tenant or shared |
| **Geo-queries** | GeoPoint (basic) | No native | **PostGIS (full)** | No | GeoJSON (full 2dsphere) |
| **Max Document/Row Size** | 1MB | 10MB | Row-based | 256MB per cell | 16MB |
| **GCP-Native** | **Yes** | **Yes** | **Yes** | **Yes** | No (third-party managed) |

**Decision:** **Firestore** for MVP. Critical advantages: real-time sync for multi-device galleries, native offline support for intermittent connectivity, and serverless pricing that scales to zero.

Mitigations for known limitations:
1. Route metadata writes through **Pub/Sub to Cloud Run** pipeline (batched writes).
2. Shard hot documents using a `shardId` field (e.g., `userId_shardN`).
3. If EXIF search grows complex, add **Cloud SQL (PostgreSQL)** as a secondary search index — it stays GCP-native and provides full SQL + JSONB querying.

---

### 3.3 CDN / Edge Caching

| Criteria | **Cloud CDN (Selected)** | Media CDN | Cloud CDN + Cloud Run (Image Proxy) |
|----------|--------------------------|-----------|-------------------------------------|
| **Edge PoPs** | ~190+ | **~1,300+ (Google's media edge)** | ~190+ |
| **Origin Integration** | GCS (native), Cloud Run (native) | GCS (native), Cloud Run (native) | GCS via Cloud Run proxy |
| **Image Transform at Edge** | No | No | **Yes (via Cloud Run proxy)** |
| **Cache Invalidation** | URL-based (minutes) | URL-based (minutes) | URL-based (minutes) |
| **WebP/AVIF Auto-convert** | No | No | **Yes (via proxy logic)** |
| **Cost (per GB egress)** | $0.08-0.12 | $0.02-0.08 (volume discounts) | $0.08-0.12 + compute |
| **Cache Hit Ratio** | High | **Very high (optimized for media)** | High |
| **Designed For** | General web content | **Large-file media delivery (video, images)** | Dynamic image serving |
| **HTTP/3 + QUIC** | Yes | Yes | Yes |
| **Custom Cache Keys** | Limited | **Advanced (header, cookie, geo)** | Full control (proxy) |
| **Signed URLs/Cookies** | Yes | Yes | Yes |

**Decision:** **Cloud CDN** for the API and general assets. Evaluate **Media CDN** for thumbnail delivery if egress costs become significant at scale — it is purpose-built for media workloads with better edge coverage and lower per-GB pricing at volume.

To compensate for the lack of edge image transformation:
1. **Pre-generate thumbnail variants** (small, medium, large) in AVIF and WebP during the processing pipeline via Cloud Run Jobs.
2. Deploy a lightweight **Cloud Run image proxy** behind Cloud CDN for on-demand resize as a cache-miss fallback. Cloud CDN caches the result, so each unique size is generated only once.
3. Use **content-hash-based URLs** (`/thumb/{hash}_{size}.avif`) to achieve effective cache invalidation without waiting for TTL expiry.

---

### 3.4 Compute (Image Processing & API)

| Criteria | Cloud Functions Gen 2 | **Cloud Run Services (Selected)** | **Cloud Run Jobs (Selected)** | GKE Autopilot | Batch |
|----------|-----------------------|-----------------------------------|-------------------------------|--------------|-------|
| **Max vCPU** | 8 | 8 | 8 | Unlimited (node pool) | 96 |
| **Max Memory** | 32GB | 32GB | 32GB | Unlimited | 896GB |
| **Max Timeout** | 60 min | 60 min | **24 hours** | Unlimited | **7 days** |
| **Concurrency per Instance** | 1 (default), up to 1000 | **Up to 1000** | 1 per task | Pod-based | 1 per task |
| **Cold Start** | 500ms-2s | 500ms-2s | N/A (batch) | Pod scheduling (~5-30s) | Minutes |
| **Event Triggers** | Eventarc / Pub/Sub | Pub/Sub / HTTP | Cloud Scheduler / HTTP | Pub/Sub / HTTP | HTTP / gcloud |
| **Container Support** | No (runtime-based) | **Yes (any container)** | **Yes (any container)** | **Yes (any container)** | **Yes (any container)** |
| **GPU Support** | No | Yes (preview) | Yes (preview) | **Yes (GA)** | **Yes (GA)** |
| **Scale to Zero** | Yes | Yes | Yes | **No (min 1 node)** | Yes |
| **Operational Overhead** | None | None | None | Medium (cluster mgmt) | None |
| **Cost Model** | Per invocation + compute time | Per request + compute time | Per task + compute time | Per node-hour | Per task + compute time |
| **Best For** | Lightweight event handlers | **APIs + medium processing** | **Heavy batch processing** | Long-running services | Very heavy batch jobs |

**Decision:** Split compute model (all GCP-native, all serverless):

| Workload | Service | Rationale |
|----------|---------|-----------|
| API layer (auth, metadata CRUD, upload URL generation) | **Cloud Run Services** | Per-instance concurrency up to 1000. Far more efficient than Functions for request/response workloads. Native Cloud CDN integration as backend. |
| Heavy image processing (AVIF encoding, batch thumbnails, multi-size generation) | **Cloud Run Jobs** | 24-hour timeout and full container support allow optimized `libavif`/`sharp` Docker builds. No timeout risk on large albums. |
| On-demand image resize (cache-miss fallback) | **Cloud Run Services** (image proxy) | Lightweight service behind Cloud CDN. Resizes on demand, result is cached at edge. Eliminates need for pre-generating every possible size. |
| Lightweight event glue (Eventarc to Pub/Sub fan-out) | **Cloud Functions Gen 2** | Retain Functions only for simple event routing where the overhead of a full container is unnecessary. |

GKE Autopilot and Batch are not justified at MVP scale. Revisit if GPU-based processing (e.g., AI tagging) is added later.

---

### 3.5 Event / Message Queue

| Criteria | **Cloud Pub/Sub (Selected)** | **Cloud Tasks (Selected)** | Cloud Scheduler | Eventarc | Workflows |
|----------|------------------------------|----------------------------|-----------------|----------|-----------|
| **Pattern** | Pub/Sub (fan-out) | Task queue (point-to-point) | Cron trigger | Event routing | Orchestration |
| **Ordering** | Optional (ordering key) | FIFO by queue | N/A | No | Step-based |
| **Delivery Guarantee** | At-least-once | At-least-once | At-most-once | At-least-once | Exactly-once (steps) |
| **Max Message Size** | 10MB | 1MB | N/A | Varies by source | Varies |
| **Retention** | 7 days (default, up to 31) | N/A (execute or fail) | N/A | N/A | Execution history |
| **Dead Letter Queue** | Yes | Yes | No | Yes | Error handling (catch) |
| **Rate Limiting** | No native | **Yes (native)** | N/A | No | Step-level concurrency |
| **Scale to Zero** | Yes | Yes | Yes | Yes | Yes |
| **Cost (per 1M operations)** | $0.40 | $0.40 | $0.10 | Included with Pub/Sub | $0.01 per step |
| **Best For** | **Event fan-out, decoupling** | **Rate-limited retryable work** | **Periodic triggers** | **GCP event routing** | **Multi-step orchestration** |

**Decision:** Use **four GCP-native services** in combination:

| Service | Role in Architecture |
|---------|---------------------|
| **Eventarc** | Routes GCS upload events and Firestore change events to Pub/Sub topics automatically. |
| **Cloud Pub/Sub** | Event fan-out hub. Upload complete event fans out to: thumbnail generation, metadata indexing, and lifecycle check — all in parallel. |
| **Cloud Tasks** | Rate-limited, retryable task execution. Lifecycle transitions and batch re-processing use Cloud Tasks to prevent GCS API quota spikes. |
| **Cloud Scheduler** | Periodic lifecycle sweeps. Runs daily/weekly to identify photos eligible for storage class transitions across all users. |

---

### 3.6 Auth / Identity Federation

| Criteria | **GCP Workload Identity Federation (Selected)** | Firebase Auth | Identity Platform | Custom OAuth2 |
|----------|--------------------------------------------------|---------------|-------------------|---------------|
| **Key-less GCS Access** | **Yes (OIDC/SAML)** | No (needs service account) | No (needs service account) | No (token-based) |
| **Token Lifetime** | 1 hour (configurable) | 1 hour (Firebase token) | 1 hour | Custom |
| **Per-bucket Granularity** | **Yes (IAM conditions)** | No | No | Scope-based |
| **User Authentication** | No (infra-level only) | **Yes (email, social, phone)** | **Yes (SAML, OIDC, MFA)** | Custom |
| **Multi-tenant Safe** | **Yes (attribute conditions)** | Yes (multi-tenant projects) | **Yes (tenant-level isolation)** | Depends |
| **Audit Trail** | Cloud Audit Logs | Firebase Analytics | Cloud Audit Logs | Custom |
| **Cost** | Free | Free (up to limits) | Per MAU above free tier | Custom |

**Decision:** Use **two auth layers**:

| Layer | Service | Purpose |
|-------|---------|---------|
| **User Authentication** | **Firebase Auth** (or Identity Platform for enterprise) | Handles user login (email, Google, Apple). Issues Firebase ID tokens. |
| **GCS Bucket Access** | **Workload Identity Federation** | Exchanges Firebase ID token for short-lived GCS credentials scoped to the user's specific bucket. No permanent keys stored. |

This separation is critical: Firebase Auth handles who the user is, Workload Identity Federation handles what GCS resources they can access.

---

### 3.7 Security / WAF / DDoS

| Criteria | **Cloud Armor (Selected)** | reCAPTCHA Enterprise | VPC Service Controls |
|----------|----------------------------|---------------------|----------------------|
| **DDoS Protection** | **Standard (free) + Managed Protection Plus (paid)** | No | No |
| **WAF Rules** | **Pre-configured + custom rules** | No | No |
| **Bot Management** | Adaptive Protection (ML-based) | **Primary purpose** | No |
| **Rate Limiting** | **Yes (per-client, per-path)** | Challenge-based | No |
| **Geo-blocking** | **Yes** | No | No |
| **API Abuse Prevention** | Rate limiting + custom rules | Bot score integration | Network-level controls |
| **Integration** | Cloud CDN, Cloud Run (via Load Balancer) | Any web frontend | GCP service perimeter |
| **Cost** | Standard: free. Plus: $3,000/mo | Per assessment ($1/1000) | Free (config-based) |

**Decision:** **Cloud Armor Standard** (free tier) in front of the Global External Application Load Balancer. This provides:

- DDoS protection for the Cloud Run API and Cloud CDN
- Rate limiting per client IP to prevent upload abuse
- Geo-blocking if needed for compliance
- Custom WAF rules to block known attack patterns

Upgrade to Cloud Armor **Managed Protection Plus** only if the platform reaches significant scale and becomes a DDoS target.

---

### 3.8 Image Processing Pipeline

Since there is no edge image transformation in the GCP-native stack, the processing pipeline must be explicitly designed.

| Criteria | **Cloud Run Jobs (Selected)** | Cloud Functions Gen 2 | GKE + GPU | Transcoder API |
|----------|-------------------------------|----------------------|-----------|----------------|
| **AVIF Encoding** | Yes (custom container with libavif/sharp) | Yes (limited by runtime) | Yes (fastest with GPU) | No (video only) |
| **Batch Processing** | **1000s of tasks in parallel** | Limited by concurrency | Pod-based scaling | N/A |
| **Custom Libraries** | **Any Docker container** | Runtime-limited | Any container | Managed (no custom) |
| **Timeout** | **24 hours** | 60 min | Unlimited | Per job |
| **Cost Efficiency** | Pay per task execution | Pay per invocation | Pay per node (always-on) | Per minute processed |
| **Operational Overhead** | None (serverless) | None | Medium (cluster) | None |

**Decision:** The image processing pipeline uses Cloud Run Jobs with the following pre-generation strategy:

| Variant | Format | Size | Use Case |
|---------|--------|------|----------|
| `thumb_sm` | AVIF | 200px wide | Gallery grid view |
| `thumb_md` | AVIF | 600px wide | Detail view preview |
| `thumb_lg` | AVIF | 1200px wide | Full-screen view on mobile |
| `thumb_xl` | WebP (fallback) | 1200px wide | Browsers without AVIF support |
| `original` | Preserved | Original | Download / full-res view |

A **Cloud Run image proxy** service sits behind Cloud CDN as a fallback for any non-pre-generated size. It generates the requested variant on demand, and Cloud CDN caches the result for all subsequent requests.

---

### 3.9 Mobile Local Database

The mobile client needs a local database for offline metadata access and thumbnail caching. This DB must support: structured queries over EXIF data, efficient blob/path storage for cached thumbnails, and reliable sync with Firestore.

| Criteria | **SQLite (via Drift/sqflite)** | Realm (MongoDB) | Hive (Dart) | ObjectBox | Isar |
|----------|-------------------------------|-----------------|-------------|-----------|------|
| **Data Model** | Relational (SQL) | Object-oriented | Key-value / typed boxes | Object-oriented | Object-oriented (NoSQL) |
| **Query Language** | **Full SQL** | Realm Query Language | Limited (key-based) | QueryBuilder | QueryBuilder + full-text search |
| **Performance (10K+ records)** | **Excellent** | Excellent | Good | **Excellent** | **Excellent** |
| **Max DB Size** | **Unlimited (disk-bound)** | Unlimited | Limited by RAM on open | Unlimited | Unlimited |
| **Offline-First** | **Yes** | Yes | Yes | Yes | Yes |
| **Built-in Sync** | No (manual) | Yes (Atlas Device Sync) | No | No (ObjectBox Sync is paid) | No |
| **Platform Support** | **iOS, Android, Web, Desktop** | iOS, Android | Dart (all Flutter) | iOS, Android, Desktop | **iOS, Android, Web, Desktop** |
| **Flutter Support** | Mature (sqflite, Drift) | Mature (realm-dart) | Native (Dart) | Mature | Mature |
| **Encryption at Rest** | Yes (SQLCipher) | Yes (built-in) | Yes (AES) | Yes | Yes |
| **Schema Migrations** | **Explicit (full control)** | Automatic | Manual | Automatic | Automatic |
| **Blob Storage** | **BLOB columns + file paths** | Binary data type | Uint8List | byte[] | byte[] |
| **License** | Public Domain | Apache 2.0 | Apache 2.0 | Apache 2.0 (core) | Apache 2.0 |
| **Maturity** | **Battle-tested (20+ years)** | Mature | Moderate | Mature | Moderate |
| **GCP/Firestore Sync** | Manual (your sync logic) | No (MongoDB ecosystem) | Manual | Manual | Manual |

**Decision:** **SQLite via Drift** (Flutter's type-safe SQL library, formerly Moor).

Rationale:
1. **Full SQL** allows complex EXIF queries locally (e.g., "photos taken in January with ISO > 800") without round-tripping to Firestore.
2. **Battle-tested reliability** — SQLite is the most deployed database engine in the world. No surprises at scale.
3. **No vendor lock-in** — unlike Realm (MongoDB ecosystem), SQLite has no dependency on a specific cloud backend.
4. **Drift** provides type-safe Dart queries, automatic schema migrations, and reactive streams that integrate cleanly with Flutter's state management.
5. **SQLCipher** extension provides AES-256 encryption at rest for cached metadata.
6. Sync with Firestore is manual but fits the architecture: use Firestore's `onSnapshot` listeners to stream changes into the local SQLite DB.

Realm was a strong contender (built-in sync), but its sync targets MongoDB Atlas, not Firestore. Using Realm would create a dependency on a non-GCP service, violating the single-vendor constraint.

---

### 3.10 Image Deduplication / Unique Identifier

The platform must generate a **device-independent, content-based unique identifier** for every image so that reinstalling the app on the same device does not trigger duplicate backups.

| Strategy | **Content Hash (SHA-256)** | Perceptual Hash (pHash) | EXIF-Based Composite Key | File Path + Modified Date | Device Media Store ID |
|----------|---------------------------|------------------------|-------------------------|--------------------------|----------------------|
| **Uniqueness** | **Globally unique per byte-identical file** | Unique per visual content (tolerant of re-encoding) | Unique per camera + timestamp + dimensions | Not unique (paths change) | Device-local only |
| **Survives Reinstall** | **Yes (content-based)** | **Yes (content-based)** | **Yes (EXIF is in file)** | No (app storage wiped) | **No (ID changes after reinstall on some OS)** |
| **Survives Re-encoding** | No (different bytes = different hash) | **Yes (visual similarity)** | Partial (EXIF may be stripped) | No | No |
| **Collision Risk** | Negligible (2^256) | Low but possible (lossy) | Medium (same camera, same second) | High | N/A |
| **Compute Cost** | Low (streaming hash) | Medium (image decode + DCT) | Very low (metadata read) | Negligible | Negligible |
| **Storage** | 32 bytes (SHA-256) | 8 bytes (64-bit hash) | ~100 bytes (composite) | Variable | 8 bytes |
| **Cross-device Dedup** | **Yes** | **Yes** | Partial | No | No |
| **Implementation Complexity** | Low | Medium (needs image processing lib) | Low | Low | Low |

**Decision:** Use a **two-layer deduplication strategy**:

**Layer 1 — Primary Identifier (Content Hash):**
```
image_uid = SHA-256(file_bytes)
```
- Computed client-side before upload.
- Stored in Firestore metadata document and in the local SQLite DB.
- If the hash already exists in the user's Firestore collection, skip the upload entirely.
- This handles the exact reinstall scenario: same device, same photos, same bytes = same hash = no duplicate backup.

**Layer 2 — Fuzzy Dedup Guard (EXIF Composite Key):**
```
exif_key = SHA-256(camera_make + camera_model + datetime_original + image_width + image_height + file_size)
```
- Catches near-duplicates where the file bytes differ slightly (e.g., OS re-encoded the HEIC, screenshots re-saved as PNG) but the photo is logically the same.
- If `image_uid` (Layer 1) doesn't match but `exif_key` matches an existing record, flag it as a **potential duplicate** and prompt the user rather than silently skipping.

**Why not perceptual hashing?**
- pHash requires decoding the full image (CPU-intensive on mobile during a batch scan of thousands of photos).
- SHA-256 can be computed as a streaming hash without loading the full image into memory.
- For the reinstall scenario specifically, file bytes are identical, so content hash is sufficient.

---

## 4. Final GCP-Native Architecture

```
+----------------------------------------------------------------------+
|                         CLIENT (Mobile/Web)                           |
|  +----------+  +--------------+  +------------+  +----------------+  |
|  | WebP     |  | BlurHash     |  | Resumable  |  | Offline-First  |  |
|  | Compress |  | Generation   |  | Upload Mgr |  | Cache (SW)     |  |
|  +----+-----+  +------+-------+  +-----+------+  +----------------+  |
+-------|-----------------|--------------|-+---------------------------+
        |                 |              |
        v                 v              v
+----------------------------------------------------------------------+
|              GLOBAL EXTERNAL APPLICATION LOAD BALANCER                 |
|                    + Cloud Armor (WAF / DDoS)                         |
+--+-------------------+-------------------+---------------------------+
   |                   |                   |
   v                   v                   v
+-------------+  +-------------+  +-----------------+
| Cloud CDN   |  | Cloud Run   |  | Cloud Run       |
| (Thumbnail  |  | (API Layer) |  | (Image Proxy)   |
|  Cache)     |  |             |  |                 |
|             |  | - Auth      |  | - On-demand     |
| Serves:     |  | - Metadata  |  |   resize        |
| - thumb_sm  |  |   CRUD      |  | - Format        |
| - thumb_md  |  | - Upload    |  |   conversion    |
| - thumb_lg  |  |   URL Gen   |  | - Cache-miss    |
| - thumb_xl  |  | - Lifecycle |  |   fallback      |
+------+------+  |   Config    |  +--------+--------+
       |         +------+------+           |
       |                |                  |
  (cache miss)          |           (generated thumb
       |                |            written back)
       v                v                  |
+------------------+  +-----------+        |
| User's GCS       |  | Cloud     |        |
| Bucket (BYOS)    |  | Pub/Sub   |        |
|                  |  | (Event    |        |
| - /originals/    |  |  Bus)     |        |
| - /thumbnails/   |<-+          |        |
| - Lifecycle      |  |  +-------+------+ |
|   Managed Tiers  |  |  |Fan-out       | |
+--------+---------+  |  |Subscribers:  | |
         |            |  | 1.Thumbnails | |
    (Eventarc)        |  | 2.Metadata   | |
         |            |  | 3.Lifecycle  | |
         v            |  +---+-----+---+ |
+------------------+  +------+-----+-----+
| Eventarc         |         |     |
| (Event Router)   |         v     v
|                  |  +--------+ +---------------+
| - GCS Object     |  |Cloud   | |Cloud Tasks    |
|   Created        |  |Run Jobs| |(Rate-limited) |
| - Firestore      |  |        | |               |
|   Changes        |  |- AVIF  | |- Lifecycle    |
+------------------+  |  Gen   | |  Transitions  |
                      |- Multi | |- Batch        |
                      |  Size  | |  Reprocess    |
                      |- EXIF  | |- Scheduled    |<-- Cloud Scheduler
                      |  Parse | |  Sweeps       |    (Daily/Weekly)
                      +---+----+ +---------------+
                          |
                          v
                   +--------------+     +---------------------+
                   | Firestore    |     | Observability       |
                   | (Metadata)   |     |                     |
                   |              |     | - Cloud Logging     |
                   | - EXIF Index |     | - Cloud Trace       |
                   | - File Paths |     | - Error Reporting   |
                   | - BlurHashes |     | - Cloud Monitoring  |
                   | - Storage    |     |   (SLOs + Alerts)   |
                   |   Class State|     +---------------------+
                   | - Thumbnail  |
                   |   URLs (hash)|
                   +--------------+

                   +--------------------------+
                   | Auth Stack               |
                   |                          |
                   | Firebase Auth             |
                   |   (User identity)        |
                   |          |                |
                   |          v                |
                   | Workload Identity         |
                   | Federation               |
                   |   (GCS bucket access)    |
                   +--------------------------+
```

---

## 5. GCP-Native Service Map

| Layer | GCP Service | Role |
|-------|-------------|------|
| **Edge / CDN** | Cloud CDN | Cache thumbnails and static assets at edge PoPs |
| **Load Balancing** | Global External Application Load Balancer | Route traffic, terminate SSL, integrate Cloud Armor and Cloud CDN |
| **WAF / DDoS** | Cloud Armor (Standard) | Rate limiting, DDoS protection, WAF rules |
| **API Compute** | Cloud Run Services | API layer (auth, metadata, upload URLs, lifecycle config) |
| **Image Proxy** | Cloud Run Services | On-demand image resize/format-convert behind Cloud CDN |
| **Batch Processing** | Cloud Run Jobs | Thumbnail generation (multi-size AVIF/WebP), EXIF parsing |
| **Event Routing** | Eventarc | Route GCS and Firestore events into Pub/Sub |
| **Event Fan-out** | Cloud Pub/Sub | Decouple upload events from processing subscribers |
| **Task Queue** | Cloud Tasks | Rate-limited lifecycle transitions, batch reprocessing |
| **Scheduler** | Cloud Scheduler | Periodic lifecycle sweeps, cleanup jobs |
| **Event Glue** | Cloud Functions Gen 2 | Lightweight Eventarc-to-Pub/Sub bridging |
| **Metadata** | Firestore | EXIF data, file paths, storage class state, BlurHashes, thumbnail URL hashes |
| **Primary Storage** | User's GCS Bucket (BYOS) | Originals, thumbnails, lifecycle-tiered objects |
| **User Auth** | Firebase Auth | Email, social, phone login |
| **Bucket Auth** | Workload Identity Federation | Key-less, scoped GCS access via short-lived tokens |
| **Observability** | Cloud Logging + Cloud Trace + Error Reporting + Cloud Monitoring | Structured logs, distributed traces, error tracking, SLO-based alerts |
| **DNS** | Cloud DNS | Domain management |
| **SSL/TLS** | Certificate Manager | Managed SSL certificates for the load balancer |
| **Mobile Local DB** | SQLite via Drift | Offline metadata cache, EXIF queries, thumbnail LRU cache, dedup authority |
| **Image Dedup** | SHA-256 content hash + EXIF composite key | Prevents duplicate backups across reinstalls and devices |
| **Metadata Sync** | Firestore onSnapshot + Cloud Run paginated API | Full sync on fresh login, real-time incremental sync thereafter |

---

## 6. Mobile Client Data Strategy

### 6.1 Local Database Schema (SQLite via Drift)

```sql
-- Core photo metadata (synced from Firestore)
CREATE TABLE photos (
    image_uid       TEXT PRIMARY KEY,   -- SHA-256 of file bytes
    exif_key        TEXT NOT NULL,       -- SHA-256 of EXIF composite
    user_id         TEXT NOT NULL,
    file_path_gcs   TEXT NOT NULL,       -- Path in user's GCS bucket
    file_name       TEXT NOT NULL,
    file_size       INTEGER NOT NULL,
    mime_type       TEXT NOT NULL,
    width           INTEGER,
    height          INTEGER,

    -- EXIF fields (indexed for local queries)
    date_taken      INTEGER,             -- Unix timestamp
    camera_make     TEXT,
    camera_model    TEXT,
    iso             INTEGER,
    aperture        REAL,
    shutter_speed   TEXT,
    focal_length    REAL,
    latitude        REAL,
    longitude       REAL,

    -- Thumbnail references
    blurhash        TEXT NOT NULL,
    thumb_sm_hash   TEXT,                -- Content-hash for CDN URL
    thumb_md_hash   TEXT,
    thumb_lg_hash   TEXT,

    -- Storage lifecycle
    storage_class   TEXT DEFAULT 'STANDARD',
    lifecycle_rule  TEXT,

    -- Sync state
    firestore_doc_id TEXT NOT NULL,
    last_synced_at   INTEGER NOT NULL,   -- Unix timestamp
    sync_version     INTEGER DEFAULT 0,  -- Conflict detection

    -- Dedup
    backup_status   TEXT DEFAULT 'pending', -- pending | uploaded | skipped_duplicate
    device_origin   TEXT                     -- Device ID that first uploaded
);

CREATE INDEX idx_photos_date ON photos(date_taken);
CREATE INDEX idx_photos_exif_key ON photos(exif_key);
CREATE INDEX idx_photos_backup ON photos(backup_status);
CREATE INDEX idx_photos_location ON photos(latitude, longitude);

-- Cached thumbnail blobs (LRU eviction managed by app)
CREATE TABLE thumbnail_cache (
    thumb_hash      TEXT PRIMARY KEY,
    thumb_size      TEXT NOT NULL,       -- sm | md | lg | xl
    image_data      BLOB NOT NULL,
    cached_at       INTEGER NOT NULL,
    last_accessed   INTEGER NOT NULL,
    byte_size       INTEGER NOT NULL
);

CREATE INDEX idx_thumb_lru ON thumbnail_cache(last_accessed);

-- Sync watermark (tracks Firestore sync position)
CREATE TABLE sync_state (
    user_id         TEXT PRIMARY KEY,
    last_sync_token TEXT,                -- Firestore resume token
    last_full_sync  INTEGER,             -- Unix timestamp of last full sync
    total_synced    INTEGER DEFAULT 0
);
```

### 6.2 Fresh Login / Full Metadata Sync Flow

When a user logs in on a new device or after reinstall:

```
Step 1: Authenticate
   Firebase Auth login
        |
        v
Step 2: Check sync state
   Query local sync_state table
   - If empty (fresh install): trigger FULL SYNC
   - If exists: trigger INCREMENTAL SYNC from last token
        |
        v
Step 3a: FULL SYNC                    Step 3b: INCREMENTAL SYNC
   Cloud Run API:                        Firestore onSnapshot with
   GET /api/v1/photos/sync               resume token from sync_state
   ?mode=full                                   |
   Response: paginated                          v
   (1000 docs per page,                  Stream changes into
    sorted by date_taken DESC)           local SQLite via Drift
        |                                reactive inserts
        v
   Batch insert into local
   SQLite (Drift batch API,
   500 rows per transaction)
        |
        v
Step 4: Thumbnail Prefetch
   Priority queue: fetch thumb_sm for
   the most recent 200 photos first
   (visible in gallery grid).
   Remaining thumbnails fetched in
   background via WorkManager / BGTask.
        |
        v
Step 5: Update sync_state
   Store Firestore resume token
   and timestamp in sync_state table.
```

**Performance targets:**
- Full sync of 10,000 photo metadata records: < 5 seconds (network) + < 2 seconds (local insert)
- Incremental sync: real-time via Firestore onSnapshot (< 500ms per change)
- Gallery usable within 3 seconds of login (BlurHash rendered immediately, thumb_sm loading in background)

### 6.3 Deduplication Flow (Reinstall Scenario)

```
User reinstalls app and logs in
        |
        v
Full metadata sync completes
(local SQLite now has all image_uid values from Firestore)
        |
        v
App scans device photo library
        |
        v
For each local photo:
   1. Compute SHA-256 (streaming, low memory)
   2. Check: Does image_uid exist in local SQLite?
      |                          |
      YES                        NO
      |                          |
      v                          v
   Mark as                  Compute exif_key
   "already backed up"      Check exif_key in SQLite
   (skip upload)               |            |
                              MATCH        NO MATCH
                               |            |
                               v            v
                          Flag as        Queue for
                          "potential      upload
                          duplicate"      (new photo)
                          (prompt user)
```

**Key design decisions:**
- **SHA-256 is computed as a streaming hash** — the full file is never loaded into memory. This allows dedup scanning of 10,000+ photos without OOM on low-end devices.
- **The local SQLite DB is the dedup authority after sync** — the app never needs to query Firestore per-photo during the scan. One full sync, then all dedup checks are local.
- **Device origin tracking** — the `device_origin` field records which device first uploaded a photo. This allows the UI to show "backed up from iPhone 15" even when viewed on a tablet.

### 6.4 Thumbnail Cache Management

The local SQLite `thumbnail_cache` table uses an **LRU eviction strategy**:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Max cache size** | 500MB (configurable) | Reasonable for most devices. ~2,500 medium thumbnails. |
| **Eviction trigger** | Cache exceeds 90% of max | Start evicting before hitting the limit. |
| **Eviction target** | Reduce to 70% of max | Evict enough to avoid frequent re-triggers. |
| **Eviction order** | `last_accessed ASC` | Least recently viewed thumbnails are evicted first. |
| **Prefetch priority** | Most recent 200 photos (thumb_sm) | Gallery grid view is the first screen users see. |
| **Background prefetch** | Remaining thumb_sm, then thumb_md for recent 50 | Progressive enhancement as bandwidth allows. |

---

## 7. Cost Projection

### Monthly estimate for 1,000 active users, 100GB average storage per user

| Service | Usage Estimate | Monthly Cost |
|---------|---------------|-------------|
| **Cloud Run (API)** | 5M requests, avg 100ms, 512MB | ~$15-25 |
| **Cloud Run (Image Proxy)** | 500K cache-miss requests, avg 300ms, 1GB | ~$10-20 |
| **Cloud Run Jobs** | 200K thumbnail tasks/mo, avg 2s, 2GB | ~$25-40 |
| **Cloud CDN** | 5TB egress/mo | ~$400-600 |
| **Cloud Armor (Standard)** | Included with LB | Free |
| **Global External ALB** | Base + per-rule | ~$20-30 |
| **Firestore** | 30M reads + 10M writes/mo | ~$30-50 |
| **Cloud Pub/Sub** | 10M messages/mo | ~$4 |
| **Cloud Tasks** | 2M tasks/mo | ~$1 |
| **Cloud Scheduler** | 100 jobs/mo | ~$0.10 |
| **Cloud Functions** | 1M lightweight invocations | ~$0.40 |
| **Cloud Logging/Trace** | 10GB logs/mo | ~$5 |
| **Firebase Auth** | 1,000 MAU | Free |
| **Cloud DNS** | 1 zone + queries | ~$1 |
| **Certificate Manager** | 1 cert | Free |
| **User's GCS (BYOS)** | Paid by user | $0 (platform cost) |
| | | |
| **Total Platform Cost** | | **~$510-770/mo** |
| **Per-user cost** | | **~$0.51-0.77/user/mo** |

> **Note:** Cloud CDN egress is the dominant cost (~75%). At higher scale, evaluate **Media CDN** for volume-based egress discounts ($0.02-0.04/GB vs $0.08-0.12/GB), which could reduce the CDN line by 50-75%.

---

## 8. Summary of Changes from Original BRD

| # | Original BRD Design | Recommended Change | Rationale |
|---|---------------------|-------------------|-----------|
| 1 | Cloud Functions for all compute | **Cloud Run Services** (API + image proxy) + **Cloud Run Jobs** (batch processing) + Cloud Functions (event glue only) | Better concurrency, longer timeouts, container flexibility, on-demand image resize |
| 2 | No message queue | **Eventarc** + **Pub/Sub** (fan-out) + **Cloud Tasks** (rate-limited work) + **Cloud Scheduler** (periodic) | Decouples ingestion from processing, adds retry semantics, dead letter queues, backpressure, and lifecycle orchestration |
| 3 | Cloud CDN (basic) | **Cloud CDN** + **Global External ALB** + **Cloud Run image proxy** | ALB enables Cloud Armor integration. Image proxy compensates for lack of edge image transforms. Content-hash URLs for effective invalidation. |
| 4 | No security layer | **Cloud Armor Standard** | WAF rules, DDoS protection, rate limiting — all through the load balancer |
| 5 | Direct Firestore writes | **Pub/Sub to batched Firestore writes** via Cloud Run | Avoids per-document write contention at high concurrency |
| 6 | No observability | **Cloud Logging + Cloud Trace + Error Reporting + Cloud Monitoring** | Structured logging, distributed tracing, SLO-based alerting |
| 7 | No conflict resolution | **Last-write-wins with device vector clock** | Handles multi-device upload conflicts |
| 8 | No cache invalidation strategy | **Content-hash-based URLs** (`/thumb/{hash}_{size}.avif`) | Bypasses Cloud CDN TTL without waiting for invalidation propagation |
| 9 | Single Firestore doc for metadata sync | **Sharded documents or subcollections by date range** | Eliminates read contention hotspot |
| 10 | Cloud Functions Gen 2 for image processing | **Cloud Run Jobs** (pre-generation) + **Cloud Run Services** (on-demand proxy) | Pre-generate common sizes; on-demand fallback for uncommon sizes. Full container control for libavif/sharp. |
| 11 | No local database on mobile | **SQLite via Drift** with LRU thumbnail cache | Offline metadata queries, EXIF search, and thumbnail caching without network round-trips. |
| 12 | No full sync mechanism | **Paginated full sync API** + **Firestore incremental sync** with resume tokens | Fresh login hydrates local DB in <7 seconds for 10K photos. Incremental sync is real-time thereafter. |
| 13 | No deduplication strategy | **Two-layer dedup: SHA-256 content hash + EXIF composite key** | Prevents duplicate backups after reinstall. Content hash is exact match; EXIF key catches near-duplicates. |

---

## 9. Tradeoffs Accepted (GCP-Native Decision)

By choosing a fully GCP-native stack over a multi-vendor approach (e.g., Cloudflare + GCP), we accept the following tradeoffs:

| Tradeoff | Impact | Mitigation |
|----------|--------|------------|
| **No edge image transformation** | All thumbnails must be pre-generated or served via origin proxy | Cloud Run image proxy behind Cloud CDN. Each variant generated once, then cached at edge. |
| **Higher egress costs** | Cloud CDN charges $0.08-0.12/GB vs Cloudflare's $0 | Evaluate Media CDN at scale. Aggressive CDN caching with long TTLs. Pre-generate common sizes to maximize cache hits. |
| **Slower cache invalidation** | Cloud CDN takes minutes vs Cloudflare's instant purge | Content-hash-based URLs make explicit invalidation unnecessary for most cases. |
| **WAF/DDoS is an add-on** | Cloudflare includes WAF/DDoS free; GCP requires Cloud Armor config | Cloud Armor Standard is free. Adequate for MVP. Upgrade to Plus at scale. |
| **Single vendor lock-in** | Entire stack depends on GCP | Accepted tradeoff for operational simplicity, unified billing, native service integration, and single IAM boundary. |

**Why this tradeoff is acceptable:** Single-vendor simplicity reduces operational overhead, consolidates billing and support, eliminates cross-vendor networking complexity, and keeps the entire auth chain (Firebase Auth to Workload Identity Federation to GCS IAM) within one trust boundary. For an MVP targeting cost-conscious users (the BYOS audience), operational simplicity outweighs marginal egress savings.

---

*End of review. Ready for implementation planning upon approval.*
