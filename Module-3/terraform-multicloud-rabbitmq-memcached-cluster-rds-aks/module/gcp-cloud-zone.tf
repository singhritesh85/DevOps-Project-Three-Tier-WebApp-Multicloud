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

##### Introduced a time sleep of 150 seconds to do the GCP DNS Nameserver entry in your domain name provider's nameserver ##### 
resource "time_sleep" "wait_150_seconds" {
  depends_on = [google_dns_managed_zone.dexter_public_zone]
  create_duration = "150s"
}

############################################# Wild Card ACM Certificate ###############################################

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "*.singhritesh85.com"
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }

  depends_on   = [time_sleep.wait_150_seconds]
}

############################################# Record Set for Certificate Validation ###################################

resource "google_dns_record_set" "record_cert_validation" {
  managed_zone = google_dns_managed_zone.dexter_public_zone.name
  name    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_type
  rrdatas = [tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_value]
  ttl     = 60
}

############################################# AWS ACM Certificate Validation ##########################################

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [google_dns_record_set.record_cert_validation.name]
}

############################################ Creation of GCP Cloud DNS CNAME-Type Record-Set ##########################

resource "google_dns_record_set" "cname_record" {
  name         = "rabbitmq.${google_dns_managed_zone.dexter_public_zone.dns_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${aws_lb.rabbitmq-application-loadbalancer.dns_name}."]
  managed_zone = google_dns_managed_zone.dexter_public_zone.name
}

