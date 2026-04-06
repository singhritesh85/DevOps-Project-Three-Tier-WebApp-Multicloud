################################# GCP Cloud Zone #########################################

resource "google_dns_managed_zone" "dexter_public_zone" {
  name        = "${var.prefix}-public-zone"
  dns_name    = "singhritesh85.com."
  description = "Public"
  visibility  = "public"

  cloud_logging_config {
    enable_logging = true
  }

  dnssec_config {
    state = "on"
  }
}
