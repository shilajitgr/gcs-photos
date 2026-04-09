# ADR-015: GitHub Actions for CI/CD

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use GitHub Actions for all CI/CD pipelines.

## Context
Need automated lint, test, build, and deploy for four components (Go server, Node.js processing, Flutter app, Terraform infra).

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Cloud Build | GCP-native, direct Cloud Run integration, but less flexible than Actions |
| Both (Actions CI + Cloud Build CD) | Best of both but adds operational complexity |

## Pipelines
| Pipeline | Trigger | Steps |
|----------|---------|-------|
| **server-ci** | Push to `server/` | golangci-lint → test → Docker build → push to Artifact Registry → deploy to Cloud Run |
| **processing-ci** | Push to `processing/` | ESLint → Jest → Docker build → push to Artifact Registry |
| **app-ci** | Push to `app/` | flutter analyze → flutter test → build APK/AAB → build web |
| **infra-ci** | Push to `infra/` | terraform fmt → validate → plan (apply on main merge) |

## Test Stages
| Stage | Tests | Trigger |
|-------|-------|---------|
| PR Check | Unit tests + lint | Every PR |
| Integration | Emulator-backed integration tests | PR to main |
| E2E | Docker Compose cross-service | Merge to main |
| Mobile E2E | Flutter integration_test on Firebase Test Lab | Nightly / release |

## Consequences
- Tight GitHub integration (PR checks, status badges)
- Deploy to Cloud Run via `google-github-actions/deploy-cloudrun`
- Artifact Registry for Docker images
- Path-filtered triggers avoid unnecessary builds
