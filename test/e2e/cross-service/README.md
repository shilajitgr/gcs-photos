# Cross-Service E2E Tests

This directory contains end-to-end tests that exercise multiple CGS Photos services together.

## Setup

All services and their dependencies (Firestore emulator, Pub/Sub emulator, fake GCS server) are
orchestrated via `docker-compose.test.yml` in the parent directory.

### Running locally

```bash
cd test/e2e
docker compose -f docker-compose.test.yml up -d --build --wait

# Run API tests
cd api && go test -v ./...

# Run pipeline tests
cd ../pipeline && npm ci && npm test

# Tear down
cd .. && docker compose -f docker-compose.test.yml down -v
```

### In CI

The `.github/workflows/e2e.yml` workflow handles the full lifecycle automatically on pushes to
`main` and on manual dispatch.

## Architecture

- **cgs-api** -- The Go API server, connected to emulators instead of real GCP services.
- **cgs-processing** -- The Node.js image processing service.
- **firestore-emulator** -- Google Cloud Firestore emulator (port 8086).
- **pubsub-emulator** -- Google Cloud Pub/Sub emulator (port 8085).
- **fake-gcs-server** -- fsouza/fake-gcs-server standing in for Google Cloud Storage (port 4443).

All services share a Docker network so they can reach each other by container name.
