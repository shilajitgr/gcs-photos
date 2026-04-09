# ADR-001: GCP-Native Single Vendor Stack

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Build the entire platform on GCP-native services only. No multi-vendor (e.g., Cloudflare + GCP).

## Context
A BYOS photo manager needs object storage, CDN, compute, metadata DB, event pipeline, auth, and security. Multi-vendor could reduce egress costs (Cloudflare R2 = $0 egress) and add edge image transforms, but increases operational complexity.

## Consequences

### Accepted Tradeoffs
| Tradeoff | Mitigation |
|----------|------------|
| No edge image transformation | Cloud Run image proxy behind Cloud CDN; each variant generated once, then cached |
| Higher egress costs ($0.08-0.12/GB vs $0) | Evaluate Media CDN at scale; aggressive caching with long TTLs |
| Slower cache invalidation (minutes vs instant) | Content-hash-based URLs make explicit invalidation unnecessary |
| WAF/DDoS is an add-on | Cloud Armor Standard is free; adequate for MVP |
| Single vendor lock-in | Accepted for: unified billing, single IAM boundary, native service integration, operational simplicity |

### Benefits
- Single trust boundary for auth chain: Firebase Auth → Workload Identity Federation → GCS IAM
- Consolidated billing and support
- No cross-vendor networking complexity
- Operational simplicity for MVP targeting cost-conscious BYOS users
