provider "cloudflare" {
  email = "${var.CLOUDFLARE_EMAIL}"
  token = "${var.CLOUDFLARE_TOKEN}"
}

resource "cloudflare_access_group" "geck_access_group" {
  account_id = "${var.CLOUDFLARE_ACCOUNT_ID}"
  name       = "geck"

  include {
    email = ["${var.CLOUDFLARE_ACCESS_EMAILS}"]
  }
}

resource "cloudflare_access_identity_provider" "google_oauth" {
  account_id = "${var.CLOUDFLARE_ACCOUNT_ID}"
  name       = "Google OAuth"
  type       = "google"
  config {
    client_id     = "${var.CLOUDFLARE_GOOGLE_CLIENT_ID}"
    client_secret = "${var.CLOUDFLARE_GOOGLE_CLIENT_SECRET}"
  }
}

data "cloudflare_access_identity_provider" "google_sso" {
  name       = "Google SSO"
  account_id = "${var.CLOUDFLARE_ACCOUNT_ID}"
}

resource "cloudflare_access_application" "applications" {
  count = length(var.CLOUDFLARE_APPLICATIONS)

  zone_id                    = "${var.CLOUDFLARE_ZONE_ID}"
  name                       = "${var.CLOUDFLARE_APPLICATIONS[count.index]}"
  domain                     = "${var.CLOUDFLARE_APPLICATIONS[count.index]}.${SERVICE_DOMAIN}"
  type                       = "self_hosted"
  session_duration           = "24h"
  allowed_idps               = [data.cloudflare_access_identity_provider.google_sso.id]
  auto_redirect_to_identity  = true
  http_only_cookie_attribute = true
}

resource "cloudflare_access_policy" "geck_access_policy" {
  for_each = cloudflare_access_application.applications[*]

  application_id = "${each.value.id}"
  zone_id        = "${var.CLOUDFLARE_ZONE_ID}"
  name           = "geck"
  precedence     = "1"
  decision       = "allow"

  include {
    email = ["${var.CLOUDFLARE_ACCESS_EMAILS}"]
  }
}

resource "cloudflare_argo_tunnel" "tunnel" {
  account_id = "${var.CLOUDFLARE_ACCOUNT_ID}"
  name       = "geck"
}

resource "cloudflare_tunnel_route" "example" {
  account_id         = "${var.CLOUDFLARE_ACCOUNT_ID}"
  tunnel_id          = cloudflare_argo_tunnel.tunnel.id
  network            = "192.0.2.24/32"
  comment            = "New tunnel route for documentation"
}