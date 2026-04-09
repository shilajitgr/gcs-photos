# ADR-013: Terraform for Infrastructure as Code

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Terraform with the GCP provider for all infrastructure provisioning.

## Context
The platform uses 15+ GCP services. Manual provisioning via Console/CLI is error-prone and unreproducible.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Pulumi (Go) | Same language as backend, type-safe, but smaller community |
| gcloud CLI scripts | Quick to start but no state management or drift detection |
| Manual provisioning | Not reproducible, not auditable |

## Consequences
- Declarative, reproducible infrastructure
- State management via GCS backend
- Plan/apply workflow with PR-based review
- Modules for reusable components: `infra/modules/observability/`, `infra/modules/networking/`, etc.
- GitHub Actions runs `terraform plan` on PR, `terraform apply` on merge to main
- GCP Project: `gcs-p-492809`
