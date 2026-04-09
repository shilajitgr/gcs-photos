# ADR-008: Two-Layer Deduplication Strategy

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use a two-layer deduplication strategy: SHA-256 content hash (exact match) + EXIF composite key (fuzzy match).

## Context
Users reinstalling the app or adding a second device must not re-upload photos that are already backed up. The dedup check must work offline after initial sync and handle 10K+ photos without OOM on low-end devices.

### Layer 1 — Content Hash (Primary)
```
image_uid = SHA-256(file_bytes)
```
- Computed client-side as a streaming hash (file never fully loaded into memory)
- If hash exists in local SQLite → skip upload
- Handles exact reinstall scenario: same device, same photos, same bytes

### Layer 2 — EXIF Composite Key (Fuzzy Guard)
```
exif_key = SHA-256(camera_make + camera_model + datetime_original + image_width + image_height + file_size)
```
- Catches near-duplicates where bytes differ (OS re-encoded HEIC, screenshot re-saved as PNG)
- If `image_uid` doesn't match but `exif_key` matches → flag as potential duplicate, prompt user

### Why Not Perceptual Hashing (pHash)?
- Requires decoding full image — CPU-intensive on mobile during batch scan
- SHA-256 is streaming, no full image in memory
- For reinstall scenario, file bytes are identical, so content hash is sufficient

## Consequences
- Zero duplicate uploads after reinstall
- Cross-device dedup via shared Firestore metadata
- Device origin tracking: `device_origin` field records which device first uploaded
- All dedup checks are local after one full sync — no per-photo Firestore queries
