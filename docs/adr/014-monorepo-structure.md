# ADR-014: Monorepo Structure

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use a single monorepo for all components: server (Go), processing (Node.js), app (Flutter), infra (Terraform), and tests.

## Context
The platform has four main components with cross-cutting changes (e.g., adding a new metadata field touches API, processing, Firestore schema, and Flutter model).

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Separate repos per component | Cleaner CI, independent deploy cycles, but harder to coordinate cross-component changes |
| Two repos (backend + client) | Common split for platform + client teams, but still splits related changes |

## Layout
```
CGS-Photos/
├── server/          # Go API (Cloud Run Service)
├── processing/      # Node.js image pipeline (Cloud Run Jobs)
├── functions/       # Cloud Functions Gen 2 (event glue)
├── app/             # Flutter (mobile + web)
├── infra/           # Terraform
├── test/e2e/        # Cross-service E2E tests
├── docs/            # ADRs, plans
└── .github/workflows/
```

## Consequences
- Single PR for cross-cutting features
- Path-filtered CI: changes to `server/` trigger only server pipeline
- Shared test fixtures in `test/e2e/fixtures/`
- Single git history for architectural traceability
