################################################## SSL Certificate and GCP ALB for RabbitMQ ############################################

# Create a DNS authorization
resource "google_certificate_manager_dns_authorization" "dns_authorization" {
  name        = "${var.prefix}-dns-auth"
  location    = "global"   
  domain      = "singhritesh85.com"
  type        = "PER_PROJECT_RECORD"   ###"FIXED_RECORD"
  description = "DNS authorization for singhritesh85.com"
}

# Create a Google-managed certificate
resource "google_certificate_manager_certificate" "gcp_certificate" {
  name        = "${var.prefix}-global-cert"
  location    = "global"    
  scope       = "DEFAULT"   ###"ALL_REGIONS"

  managed {
    domains = ["*.singhritesh85.com"]   ###[google_certificate_manager_dns_authorization.dns_authorization.domain]
    dns_authorizations = [google_certificate_manager_dns_authorization.dns_authorization.id]
  }
}

# Create a certificate map
resource "google_certificate_manager_certificate_map" "gcp_certificate_map" {
  name        = "${var.prefix}-certificate-map"
  description = "Certificate map for *.singhritesh85.com"
}

# Create a certificate map entry
resource "google_certificate_manager_certificate_map_entry" "gcp_certificate_map_entry" {
  name          = "${var.prefix}-certificate-map-entry"
  map           = google_certificate_manager_certificate_map.gcp_certificate_map.name
  certificates  = [google_certificate_manager_certificate.gcp_certificate.id]
  hostname      = "*.singhritesh85.com"
}

# URL Map
resource "google_compute_url_map" "rabbitmq_urlmap" {
  name        = "${var.prefix}-urlmap"
  description = "${var.prefix} Routing Rules for GCP ALB"

  default_service = google_compute_backend_service.gcp_alb_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.gcp_alb_backend.id
  }

  test {
    service = google_compute_backend_service.gcp_alb_backend.id
    host    = "rabbitmq.singhritesh85.com"
    path    = "/"
  }
}

resource "google_compute_url_map" "http_redirect" {
  name = "${var.prefix}-http-redirect"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"  ### 301 redirect
    strip_query            = false
    https_redirect         = true  ### Redirection is happening 
  }
}

resource "google_compute_instance_group" "rabbitmq_server" {
  name        = "rabbitmq-server-instance-group"
  description = "Instance Group for RabbitMQ Server"
  zone        = google_compute_instance.vm_instance[0].zone ### For GitLab-Server VM Instance  ###"us-central1-a"

  instances = [google_compute_instance.vm_instance[0].id, google_compute_instance.vm_instance[1].id, google_compute_instance.vm_instance[2].id]

  named_port {
    name = "rabbitmq-application"
    port = "15672"
  }
}

resource "google_compute_backend_service" "gcp_alb_backend" {
  name     = "${var.prefix}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group.rabbitmq_server.id
  }

  health_checks = [google_compute_http_health_check.gcp_alb_health_check.id]
  port_name     = "rabbitmq-application"  ### The same name should appear in the instance groups referenced by this service.

  log_config {
    enable          = true
    optional_mode   = "CUSTOM"
    optional_fields = [ "orca_load_report", "tls.protocol" ]
  }
}

resource "google_compute_http_health_check" "gcp_alb_health_check" {
  name                = "${var.prefix}-healthcheck"
  request_path        = "/"
  port                = 15672
  check_interval_sec  = 5
  timeout_sec         = 3
  healthy_threshold   = 2
  unhealthy_threshold = 2 
}

resource "google_compute_global_address" "alb_static_ip" {
  name         = "${var.prefix}-static-ip"
  address_type = "EXTERNAL"
  description  = "Static IP for the GCP ALB"
}

resource "google_compute_global_forwarding_rule" "lb_frontend_https" {
  name                  = "${var.prefix}-lb-frontend-https"
  target                = google_compute_target_https_proxy.gcp_target_https_proxy.id
  port_range            = "443"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.alb_static_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
}

resource "google_compute_global_forwarding_rule" "lb_frontend_http" {
  name                  = "${var.prefix}-lb-frontend-http"
  target                = google_compute_target_http_proxy.gcp_target_http_proxy.id
  port_range            = "80"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.alb_static_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
}

resource "google_compute_target_https_proxy" "gcp_target_https_proxy" {
  name             = "${var.prefix}-https-proxy"
  url_map          = google_compute_url_map.rabbitmq_urlmap.id
  certificate_map  = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.gcp_certificate_map.id}"
}

resource "google_compute_target_http_proxy" "gcp_target_http_proxy" {
  name             = "${var.prefix}-http-proxy"
  url_map          = google_compute_url_map.http_redirect.id
}

########################################### GCP Rabbitmq Server ################################################################################

# Service Account in GCP
resource "google_service_account" "rabbitmq_sa" {
  account_id   = "${var.prefix}-sa"
  display_name = "${var.prefix} Service Account"
}

resource "google_project_iam_member" "compute_os_login_iam" {
  project = var.project_name
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.rabbitmq_sa.email}"
}

resource "google_project_iam_member" "service_account_user_iam" {
  project = var.project_name
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.rabbitmq_sa.email}"
}

resource "google_project_iam_member" "service_account_token_creator_iam" {
  project = var.project_name
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.rabbitmq_sa.email}"
}

############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  count        = 3
  name         = "${var.prefix}-instance-internal-ip-${count.index + 1}"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gke_subnet.id     ###google_compute_subnetwork.gke_public_subnet.id 
  address      = "10.10.0.${100 + count.index}"
}

##################################################### Firewall Rule for RabbitMQ Server ##########################################################

resource "google_compute_firewall" "firewall_rule_for_rabbitmq_server" {
  name    = "allow-rabbitmq-ingress"
  network = google_compute_network.gke_vpc.id  # Replace with your VPC network name

  allow {
    protocol = "tcp"
    ports    = ["25672", "5672", "4369"]
  }

  source_ranges = ["172.25.0.0/16", "192.168.0.0/16", "10.10.0.0/20", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]
  target_tags   = ["allow-rabbitmq"] # Replace with your desired target tag
}

################################################ Create GCP Compute Engine VM instance ##########################################################

#resource "google_compute_address" "vm_static_ip" {
#  count        = 3
#  name         = "rabbitmq-static-ip-${count.index + 1}"
#  address_type = "EXTERNAL"
#  region       = "us-central1"  # Replace with your desired region
#  ip_version   = "IPV4"         # Default value is IPV4
#}

resource "google_compute_instance" "vm_instance" {
  count        = 3
  name         = "${var.prefix}-rabbitmq-vm-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20260213"
      size  = 20
      type  = "pd-standard" ### Select among pd-standard, pd-balanced or pd-ssd.
      architecture = "X86_64"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.gke_subnet.id      ###google_compute_subnetwork.gke_public_subnet.id
    network_ip = google_compute_address.instance_internal_ip[count.index].address
#    access_config {
#      nat_ip = google_compute_address.vm_static_ip[count.index].address   ### Static IP Assigned to GCP VM Instance.
#    }
  }
  service_account {
    email = google_service_account.rabbitmq_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("startup-rabbitmq.sh")

  tags = ["allow-ssh", "allow-health-check", "allow-rabbitmq"]

  depends_on = [google_compute_disk.persistent_disk]
}

resource "google_compute_disk" "persistent_disk" {
  count = 3
  name  = "${var.prefix}-persistent-disk-${count.index + 1}"
  type  = "pd-standard"
  zone  = "us-central1-a"
  size  = 20
}

resource "google_compute_attached_disk" "attach_persistent_disk" {
  count    = 3
  disk     = google_compute_disk.persistent_disk[count.index].id
  instance = google_compute_instance.vm_instance[count.index].id
}

