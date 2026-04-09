# ADR-016: Full Observability Stack

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Implement comprehensive observability across server and client using OpenTelemetry, GCP-native monitoring, and Firebase client-side tools.

## Context
A distributed system with user-owned buckets, async event pipelines, and multi-device sync requires excellent visibility into every layer.

## Server Side
| Layer | Tool |
|-------|------|
| Structured Logging | zerolog → stdout → Cloud Logging (correlation via trace ID) |
| Distributed Tracing | OpenTelemetry SDK → Cloud Trace (end-to-end: API → Pub/Sub → Jobs → Firestore) |
| Error Tracking | Cloud Error Reporting (auto-grouping, stack traces, affected user counts) |
| Custom Metrics | OpenTelemetry Metrics → Cloud Monitoring (upload latency, thumbnail gen time, dedup hit rate) |
| SLOs | Cloud Monitoring SLOs: API p99 < 200ms, thumbnail gen p99 < 10s, upload success > 99.5% |
| Alerting | Cloud Monitoring → PagerDuty/Slack (SLO burn rate, error spikes, DLQ depth) |
| Dashboards | Per-service: request rate, latency, errors, instances, memory/CPU. Pipeline: queue depth, throughput, DLQ. |
| Uptime Checks | External health probes every 60s from multiple regions |
| Profiling | Cloud Profiler (continuous CPU/heap profiling for Go API, low overhead) |
| Audit | Cloud Audit Logs (admin activity + data access for Firestore, GCS, IAM) |

## Client Side
| Layer | Tool |
|-------|------|
| Crash Reporting | Firebase Crashlytics (stack traces, device info, breadcrumbs) |
| Analytics | Firebase Analytics (screen views, uploads, sync, gallery interactions) |
| Performance | Firebase Performance Monitoring (network latency, startup time, render time) |
| Remote Config | Firebase Remote Config (feature flags, cache tuning without app update) |

## Key Packages
- Go: `go.opentelemetry.io/otel`, `opentelemetry-operations-go`, `cloud.google.com/go/profiler`
- Node.js: `@opentelemetry/sdk-node`, `@google-cloud/opentelemetry-cloud-trace-exporter`
- Flutter: `firebase_crashlytics`, `firebase_analytics`, `firebase_performance`

## Terraform Resources (`infra/modules/observability/`)
- Dashboards, alert policies, uptime checks, notification channels, log-based metrics, log sinks (BigQuery for long-term analysis)

## Consequences
- End-to-end trace from mobile HTTP request through API, Pub/Sub, processing job, back to Firestore
- SLO-based alerting catches degradation before user impact
- Cloud Profiler always-on with negligible overhead — no "reproduce in staging" needed
- Firebase Crashlytics gives real-time mobile crash visibility with breadcrumbs
