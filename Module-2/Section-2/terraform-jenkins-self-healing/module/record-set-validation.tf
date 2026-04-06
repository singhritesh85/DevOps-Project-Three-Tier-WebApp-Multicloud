############################################# Wild Card ACM Certificate ###############################################

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "*.singhritesh85.com"
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }
}

############################################# Record Set for Certificate Validation ###################################

resource "google_dns_record_set" "record_cert_validation" {
  managed_zone = var.managed_zone_name
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

#################################### Creation of GCP Cloud DNS CNAME-Type Record-Set ##################################

resource "google_dns_record_set" "cname_record" {
  name         = "jenkins-ms.singhritesh85.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${aws_lb.test-application-loadbalancer.dns_name}."]
  managed_zone = var.managed_zone_name
}
