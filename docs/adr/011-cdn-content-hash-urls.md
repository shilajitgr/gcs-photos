# ADR-011: Cloud CDN with Content-Hash-Based URLs

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Cloud CDN for thumbnail delivery with content-hash-based URLs (`/thumb/{hash}_{size}.avif`) to eliminate cache invalidation.

## Context
When a user deletes or re-processes a photo, stale thumbnails would persist at CDN edge until TTL expiry. Cloud CDN invalidation takes minutes.

## Architecture
- Cloud CDN sits behind a Global External Application Load Balancer
- Cloud Armor Standard (free) provides WAF/DDoS protection at the LB
- A Cloud Run image proxy serves as cache-miss fallback for on-demand resize
- All thumbnail URLs include the content hash — new versions automatically bypass cache

## Consequences
- No explicit cache invalidation needed for most cases
- Long TTLs possible (aggressive caching) since URL changes on content change
- Cloud CDN egress is the dominant cost (~75% of platform cost at $0.08-0.12/GB)
- At scale: evaluate Media CDN ($0.02-0.04/GB) for 50-75% CDN cost reduction
- Pre-generate 4 thumbnail variants; on-demand proxy covers edge cases
