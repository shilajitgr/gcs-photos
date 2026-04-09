# ---------------------------------------------------------------------------
# Observability — Monitoring, alerting, uptime checks, log sinks
# ---------------------------------------------------------------------------

# ── Notification Channel ───────────────────────────────────────────────────

resource "google_monitoring_notification_channel" "email" {
  count = var.notification_email != "" ? 1 : 0

  project      = var.project_id
  display_name = "CGS Photos Alert Email"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

locals {
  notification_channels = var.notification_email != "" ? [google_monitoring_notification_channel.email[0].id] : []
}

# ── Uptime Check — API /healthz ────────────────────────────────────────────

resource "google_monitoring_uptime_check_config" "api_health" {
  project      = var.project_id
  display_name = "CGS API Health Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.domain_name
    }
  }
}

# ── Alert: Cloud Run Error Rate ────────────────────────────────────────────

resource "google_monitoring_alert_policy" "cloud_run_error_rate" {
  project      = var.project_id
  display_name = "CGS API — High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run 5xx error rate > 5%"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"cloud_run_revision\"",
        "resource.labels.service_name = \"${var.api_service_name}\"",
        "metric.type = \"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class = \"5xx\"",
      ])

      comparison      = "COMPARISON_GT"
      threshold_value = 0.05
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }
}

# ── Alert: Pub/Sub DLQ Depth ──────────────────────────────────────────────

resource "google_monitoring_alert_policy" "dlq_depth" {
  project      = var.project_id
  display_name = "CGS — DLQ Messages Accumulating"
  combiner     = "OR"

  conditions {
    display_name = "DLQ unacked messages > 10"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"pubsub_subscription\"",
        "resource.labels.subscription_id = \"photo-uploads-dlq-sub\"",
        "metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\"",
      ])

      comparison      = "COMPARISON_GT"
      threshold_value = 10
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "3600s"
  }
}

# ── Log-based Metric: Processing Errors ────────────────────────────────────

resource "google_logging_metric" "processing_errors" {
  project = var.project_id
  name    = "cgs-processing-errors"
  filter  = "resource.type=\"cloud_run_job\" AND resource.labels.job_name=\"cgs-processing\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "CGS Processing Errors"
  }
}

# ── Log Sink: Processing Errors to separate bucket ─────────────────────────

resource "google_logging_project_sink" "processing_errors" {
  project                = var.project_id
  name                   = "cgs-processing-error-sink"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/cgs-processing-errors"
  filter                 = "resource.type=\"cloud_run_job\" AND resource.labels.job_name=\"cgs-processing\" AND severity>=ERROR"
  unique_writer_identity = true
}

resource "google_logging_project_bucket_config" "processing_errors" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "cgs-processing-errors"
  retention_days = 30
  description    = "Log bucket for CGS processing job errors"
}
