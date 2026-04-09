# CGS Photos — Finalized Tech Stack

## Context
CGS Photos is a BYOS (Bring Your Own Storage) photo manager. The architecture review (`ARCHITECTURE_REVIEW.md`) defines the GCP-native infrastructure. This plan finalizes the implementation tech stack across server, client backend, and client frontend so development can begin.

---

## Monorepo Structure

```
CGS-Photos/
├── server/              # Go API server (Cloud Run Service)
│   ├── cmd/api/         # Entrypoint
│   ├── internal/        # Business logic, handlers, middleware
│   ├── pkg/             # Shared utilities
│   ├── Dockerfile
│   └── go.mod
├── processing/          # Node.js image pipeline (Cloud Run Jobs)
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── functions/           # Cloud Functions Gen 2 (event glue)
│   └── eventrouter/
├── app/                 # Flutter client (mobile + web)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
├── infra/               # Terraform (GCP provisioning)
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
├── test/                # Cross-service E2E tests
│   └── e2e/
├── .github/workflows/   # GitHub Actions CI/CD
├── .mcp.json
├── CLAUDE.md
└── ARCHITECTURE_REVIEW.md
```

---

## Server Side

### API Server — `server/`
| Component | Choice | Why |
|-----------|--------|-----|
| **Language** | Go | Fast cold starts on Cloud Run, low memory, excellent concurrency |
| **Framework** | Chi (go-chi/chi) | Lightweight, stdlib-compatible, idiomatic middleware |
| **Auth** | Firebase Admin SDK (Go) | Verify Firebase ID tokens, integrate with Workload Identity Federation |
| **Firestore Client** | cloud.google.com/go/firestore | Official Go SDK, batched writes |
| **GCS Client** | cloud.google.com/go/storage | Signed URL generation, bucket operations |
| **Pub/Sub Client** | cloud.google.com/go/pubsub | Publish upload events for fan-out |
| **Config** | envconfig or Viper | Env-var based config for Cloud Run |
| **Logging** | Cloud Logging (zerolog → stdout as structured JSON) | Cloud Run captures stdout, structured logs integrate with Cloud Logging |
| **Tracing** | OpenTelemetry → Cloud Trace | Distributed tracing across services |
| **Containerization** | Multi-stage Docker build (distroless base) | Minimal image size, secure |
| **Deploy target** | Cloud Run Service | Behind Global External ALB + Cloud Armor |

### Image Processing Pipeline — `processing/`
| Component | Choice | Why |
|-----------|--------|-----|
| **Language** | Node.js (TypeScript) | Best ecosystem for Sharp |
| **Image library** | Sharp (libvips) | AVIF/WebP encoding, multi-size thumbnails, EXIF parsing |
| **EXIF parsing** | exif-reader (via Sharp metadata) | Extract camera info, GPS, timestamps |
| **BlurHash** | blurhash (npm) | Generate BlurHash strings for progressive loading |
| **Hash** | Node.js crypto (SHA-256) | Content-hash computation for dedup + CDN URLs |
| **Firestore Client** | @google-cloud/firestore | Write processed metadata |
| **GCS Client** | @google-cloud/storage | Read originals, write thumbnails |
| **Deploy target** | Cloud Run Jobs | 24h timeout, parallel task execution |

### Event Glue — `functions/`
| Component | Choice | Why |
|-----------|--------|-----|
| **Runtime** | Node.js (TypeScript) | Lightweight Eventarc→Pub/Sub bridging |
| **Framework** | @google-cloud/functions-framework | Cloud Functions Gen 2 |

---

## Client Side — `app/`

### Frontend (UI)
| Component | Choice | Why |
|-----------|--------|-----|
| **Framework** | Flutter 3.x | Single codebase: Android + iOS + Web |
| **State management** | Riverpod | Type-safe, reactive, works with Drift streams |
| **Routing** | go_router | Declarative, deep-link support (Play Store requirements) |
| **Image loading** | cached_network_image | CDN thumbnail loading with placeholder support |
| **BlurHash rendering** | flutter_blurhash | Display BlurHash placeholders during load |
| **UI components** | Material 3 (material_design) | Modern, adaptive across platforms |
| **Responsive layout** | flutter_adaptive_scaffold | Gallery grid adapts to mobile/tablet/web |

### Backend (Local)
| Component | Choice | Why |
|-----------|--------|-----|
| **Local database** | SQLite via Drift | Type-safe SQL, reactive streams, schema migrations |
| **Encryption** | SQLCipher (via drift + sqlite3_flutter_libs) | AES-256 encryption at rest |
| **Auth** | firebase_auth | Email, Google, Apple sign-in |
| **Cloud storage** | firebase_storage / gcloud REST | Resumable uploads to user's GCS bucket |
| **Firestore sync** | cloud_firestore | Real-time `onSnapshot` for incremental sync |
| **Background work** | workmanager | Background thumbnail prefetch, upload queue |
| **HTTP client** | dio | API calls to Cloud Run backend |
| **Hashing** | crypto (dart) | SHA-256 streaming hash for dedup |
| **Photo access** | photo_manager | Access device photo library for backup scan |
| **Permissions** | permission_handler | Camera, storage, photo library permissions |

---

## Infrastructure — `infra/`

| Component | Choice | Why |
|-----------|--------|-----|
| **IaC** | Terraform | GCP provider, state management, reproducible |
| **GCP Project** | gcs-p-492809 | Already configured |
| **Key resources** | Cloud Run (API + proxy + jobs), Firestore, Pub/Sub, Cloud Tasks, Cloud Scheduler, Cloud CDN, ALB, Cloud Armor, Firebase Auth, Artifact Registry | Per architecture review |
| **Container registry** | Artifact Registry | GCP-native Docker registry |
| **Secrets** | Secret Manager | API keys, Firebase config |

---

## CI/CD — `.github/workflows/`

| Pipeline | Trigger | Steps |
|----------|---------|-------|
| **server-ci** | Push to `server/` | Go lint (golangci-lint), test, build Docker, push to Artifact Registry, deploy to Cloud Run |
| **processing-ci** | Push to `processing/` | Node lint (ESLint), test, build Docker, push to Artifact Registry |
| **app-ci** | Push to `app/` | Flutter analyze, test, build APK/AAB, build web |
| **infra-ci** | Push to `infra/` | Terraform fmt, validate, plan (apply on main merge) |

---

## Play Store & Web Discoverability

- **Play Store**: Flutter builds signed AAB via GitHub Actions → publish to Play Console (manual or Fastlane)
- **iOS App Store**: Flutter builds IPA → publish to App Store Connect
- **Web**: Flutter web build deployed as static assets (Firebase Hosting or Cloud Storage + Cloud CDN)
- **SEO**: Flutter web with proper meta tags, server-side rendering not available but pre-rendering possible via `flutter build web --web-renderer html`

---

## Observability Stack (Excellent Tier)

### Server Side (Go API + Node.js Processing)
| Layer | Tool | Details |
|-------|------|---------|
| **Structured Logging** | zerolog → Cloud Logging | JSON logs to stdout, auto-ingested by Cloud Run. Correlation via trace ID. Log severity levels enforced. |
| **Distributed Tracing** | OpenTelemetry SDK → Cloud Trace | End-to-end traces: API request → Pub/Sub → Processing Job → Firestore write. Trace context propagated via W3C headers. |
| **Error Tracking** | Cloud Error Reporting | Auto-groups errors, stack traces, affected user counts. Alerts on new error groups. |
| **Metrics** | OpenTelemetry Metrics → Cloud Monitoring | Custom metrics: upload latency, thumbnail generation time, dedup hit rate, sync duration. |
| **SLOs** | Cloud Monitoring SLOs | Defined for: API latency (p99 < 200ms), thumbnail generation (p99 < 10s), upload success rate (> 99.5%) |
| **Alerting** | Cloud Monitoring Alert Policies | PagerDuty/Slack integration. Alerts on: SLO burn rate, error rate spikes, Cloud Run instance count, Pub/Sub dead-letter queue depth |
| **Dashboards** | Cloud Monitoring Dashboards | Per-service dashboards: request rate, latency histograms, error rate, active instances, memory/CPU. Pipeline dashboard: queue depth, processing throughput, DLQ size. |
| **Uptime Checks** | Cloud Monitoring Uptime Checks | External health probes on API endpoints every 60s from multiple regions |
| **Audit Logging** | Cloud Audit Logs | Admin activity + data access logs for Firestore, GCS, IAM |
| **Profiling** | Cloud Profiler | Continuous CPU/heap profiling for Go API server (low overhead, always-on) |

### Client Side (Flutter)
| Layer | Tool | Details |
|-------|------|---------|
| **Crash Reporting** | Firebase Crashlytics | Real-time crash reports with stack traces, device info, breadcrumbs |
| **Analytics** | Firebase Analytics | Screen views, upload events, sync completion, gallery interactions |
| **Performance** | Firebase Performance Monitoring | Network request latency (API + CDN), app startup time, screen rendering time |
| **Remote Config** | Firebase Remote Config | Feature flags, thumbnail cache size tuning, sync batch size — without app update |

### Key Observability Packages
| Repo Path | Package | Purpose |
|-----------|---------|---------|
| `server/` | `go.opentelemetry.io/otel` | Traces + metrics SDK |
| `server/` | `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp` | Auto-instrument Chi HTTP handlers |
| `server/` | `github.com/GoogleCloudPlatform/opentelemetry-operations-go` | Cloud Trace + Cloud Monitoring exporters |
| `server/` | `cloud.google.com/go/profiler` | Cloud Profiler agent |
| `processing/` | `@opentelemetry/sdk-node` | Auto-instrumentation for Node.js |
| `processing/` | `@google-cloud/opentelemetry-cloud-trace-exporter` | Export traces to Cloud Trace |
| `app/` | `firebase_crashlytics` | Crash reporting |
| `app/` | `firebase_analytics` | Event analytics |
| `app/` | `firebase_performance` | Network + rendering perf |

### Terraform Observability Resources (`infra/modules/observability/`)
- Cloud Monitoring dashboards (as code)
- Alert policies (SLO burn rate, error rate, DLQ depth)
- Uptime checks
- Notification channels (Slack/PagerDuty)
- Log-based metrics (custom patterns)
- Log sinks (BigQuery for long-term analysis if needed)

---

## Testing Strategy

### Unit Tests
| Component | Framework | Details |
|-----------|-----------|---------|
| `server/` | Go `testing` + testify | Handler tests, service logic, mock Firestore/GCS via interfaces |
| `processing/` | Jest (TypeScript) | Sharp pipeline tests, hash computation, EXIF extraction |
| `app/` | flutter_test + mocktail | Widget tests, Riverpod provider tests, Drift DAO tests |

### Integration Tests
| Component | Framework | Details |
|-----------|-----------|---------|
| `server/` | Go `testing` + testcontainers-go | Firestore emulator, Pub/Sub emulator — real GCP emulators in Docker |
| `processing/` | Jest + testcontainers | GCS emulator (fake-gcs-server), process real test images |
| `app/` | flutter_test + Drift in-memory DB | Test sync logic, dedup flows, LRU cache eviction against real SQLite |

### End-to-End Tests
| Scope | Framework | What It Covers |
|-------|-----------|----------------|
| **API E2E** | Go `testing` + httptest (or hurl) | Full request lifecycle: auth → upload URL → metadata CRUD → sync endpoint. Runs against Firestore + Pub/Sub emulators. |
| **Pipeline E2E** | Custom Node.js test harness | Upload image to fake GCS → trigger processing job → verify thumbnails generated (all 4 variants) → verify Firestore metadata written → verify BlurHash generated |
| **Mobile E2E** | integration_test (Flutter) + patrol | Full user flows on real device/emulator: login → gallery load → photo upload → dedup detection → thumbnail display → offline mode → sync recovery |
| **Web E2E** | integration_test (Flutter web) | Same flows as mobile, running in Chrome |
| **Cross-service E2E** | Docker Compose test environment | All services running locally: Go API + Node.js processing + Firestore emulator + Pub/Sub emulator + fake-gcs-server. Test: upload photo end-to-end from HTTP request to thumbnail in GCS and metadata in Firestore. |

### E2E Test Infrastructure
```
test/
├── e2e/
│   ├── docker-compose.test.yml   # All services + emulators
│   ├── api/                      # API E2E tests (Go or hurl)
│   ├── pipeline/                 # Processing pipeline E2E
│   ├── cross-service/            # Full flow tests
│   └── fixtures/                 # Test images (JPEG, HEIC, PNG)
├── app/integration_test/         # Flutter integration tests
│   ├── login_flow_test.dart
│   ├── upload_flow_test.dart
│   ├── dedup_flow_test.dart
│   ├── offline_sync_test.dart
│   └── gallery_browse_test.dart
```

### Key E2E Packages
| Repo Path | Package | Purpose |
|-----------|---------|---------|
| `server/` | `github.com/testcontainers/testcontainers-go` | Spin up Firestore/Pub/Sub emulators in tests |
| `processing/` | `testcontainers` (npm) | GCS emulator containers |
| `test/e2e/` | `docker-compose` | Orchestrate full local environment |
| `test/e2e/` | `hurl` (optional) | Declarative HTTP E2E test runner |
| `app/` | `integration_test` (Flutter SDK) | On-device integration tests |
| `app/` | `patrol` | Native interaction testing (permissions, notifications) |

### CI Test Pipeline (GitHub Actions)
| Stage | Tests Run | Trigger |
|-------|-----------|---------|
| **PR Check** | Unit tests (all) + lint | Every PR |
| **Integration** | Integration tests with emulators | PR to main |
| **E2E** | Docker Compose cross-service E2E | Merge to main |
| **Mobile E2E** | Flutter integration_test on Firebase Test Lab | Nightly / release branch |

---

## Verification

After scaffolding:
1. `cd server && go build ./...` — Go API compiles
2. `cd processing && npm install && npm run build` — Processing pipeline compiles
3. `cd app && flutter analyze && flutter test` — Flutter client passes analysis
4. `cd infra && terraform init && terraform validate` — Terraform config valid
5. `docker build -t cgs-api ./server` — API container builds
6. `docker build -t cgs-processing ./processing` — Processing container builds
