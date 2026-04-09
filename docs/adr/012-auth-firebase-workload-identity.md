# ADR-012: Firebase Auth + Workload Identity Federation (Two-Layer Auth)

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use two separate auth layers: Firebase Auth for user identity, Workload Identity Federation for GCS bucket access.

## Context
In a BYOS model, the platform must authenticate the user AND authorize access to their specific GCS bucket without storing permanent service account keys.

## Auth Layers
| Layer | Service | Purpose |
|-------|---------|---------|
| User Authentication | **Firebase Auth** | Email, Google, Apple sign-in. Issues Firebase ID tokens. |
| GCS Bucket Access | **Workload Identity Federation** | Exchanges Firebase ID token for short-lived GCS credentials scoped to user's bucket. No permanent keys. |

## Why Two Layers?
Firebase Auth handles *who the user is*. Workload Identity Federation handles *what GCS resources they can access*. This separation:
- Eliminates permanent service account keys (security)
- Provides per-bucket IAM granularity via attribute conditions
- Keeps the entire auth chain within one GCP trust boundary
- Token lifetime: 1 hour (configurable)
- Full audit trail via Cloud Audit Logs

## Consequences
- No stored credentials for user bucket access
- Short-lived tokens reduce blast radius of token theft
- Multi-tenant safe via attribute conditions on the Workload Identity Pool
