# ---------------------------------------------------------------------------
# Networking — Global External ALB, Cloud CDN, Cloud Armor, SSL
# ---------------------------------------------------------------------------

# ── Global IP ───────────────────────────────────────────────────────────────

resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "cgs-photos-lb-ip"
}

# ── Managed SSL Certificate ────────────────────────────────────────────────

resource "google_compute_managed_ssl_certificate" "default" {
  count   = var.domain_name != "" ? 1 : 0
  project = var.project_id
  name    = "cgs-photos-ssl-cert"

  managed {
    domains = [var.domain_name]
  }
}

# ── Cloud Armor Security Policy ────────────────────────────────────────────

resource "google_compute_security_policy" "default" {
  project = var.project_id
  name    = "cgs-photos-waf"

  # Default rule: allow
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # Rate limiting rule
  rule {
    action   = "throttle"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limit: 100 requests per minute per IP"
  }

  # Block known bad patterns (basic WAF)
  rule {
    action   = "deny(403)"
    priority = 900
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Block XSS attacks"
  }

  rule {
    action   = "deny(403)"
    priority = 901
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Block SQL injection attacks"
  }
}

# ── Serverless NEGs (Cloud Run backends) ───────────────────────────────────

resource "google_compute_region_network_endpoint_group" "api" {
  project               = var.project_id
  name                  = "cgs-api-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.api_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "proxy" {
  project               = var.project_id
  name                  = "cgs-proxy-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.proxy_service_name
  }
}

# ── Backend Services ───────────────────────────────────────────────────────

resource "google_compute_backend_service" "api" {
  project = var.project_id
  name    = "cgs-api-backend"

  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.default.id

  backend {
    group = google_compute_region_network_endpoint_group.api.id
  }

  log_config {
    enable      = true
    sample_rate = 0.5
  }
}

resource "google_compute_backend_service" "proxy" {
  project = var.project_id
  name    = "cgs-proxy-backend"

  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.default.id

  # Cloud CDN enabled for thumbnail serving
  enable_cdn = true
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 86400  # 1 day
    max_ttl                      = 604800 # 7 days
    signed_url_cache_max_age_sec = 3600
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }

  backend {
    group = google_compute_region_network_endpoint_group.proxy.id
  }

  log_config {
    enable      = true
    sample_rate = 0.1
  }
}

# ── URL Map (routing) ─────────────────────────────────────────────────────

resource "google_compute_url_map" "default" {
  project         = var.project_id
  name            = "cgs-photos-url-map"
  default_service = google_compute_backend_service.api.id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "cgs-paths"
  }

  path_matcher {
    name            = "cgs-paths"
    default_service = google_compute_backend_service.api.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api.id
    }

    path_rule {
      paths   = ["/thumb/*"]
      service = google_compute_backend_service.proxy.id
    }
  }
}

# ── HTTPS Proxy + Forwarding Rule ─────────────────────────────────────────

resource "google_compute_target_https_proxy" "default" {
  count   = var.domain_name != "" ? 1 : 0
  project = var.project_id
  name    = "cgs-photos-https-proxy"
  url_map = google_compute_url_map.default.id

  ssl_certificates = [google_compute_managed_ssl_certificate.default[0].id]
}

resource "google_compute_global_forwarding_rule" "https" {
  count      = var.domain_name != "" ? 1 : 0
  project    = var.project_id
  name       = "cgs-photos-https-rule"
  target     = google_compute_target_https_proxy.default[0].id
  ip_address = google_compute_global_address.default.address
  port_range = "443"

  load_balancing_scheme = "EXTERNAL_MANAGED"
  labels                = var.labels
}

# ── HTTP → HTTPS Redirect ─────────────────────────────────────────────────

resource "google_compute_url_map" "http_redirect" {
  project = var.project_id
  name    = "cgs-photos-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  project = var.project_id
  name    = "cgs-photos-http-redirect-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  project    = var.project_id
  name       = "cgs-photos-http-redirect-rule"
  target     = google_compute_target_http_proxy.redirect.id
  ip_address = google_compute_global_address.default.address
  port_range = "80"

  load_balancing_scheme = "EXTERNAL_MANAGED"
}
