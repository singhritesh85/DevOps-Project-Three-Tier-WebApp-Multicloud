########################################### GCP Memcached Server ################################################################################

# Service Account in GCP
resource "google_service_account" "memcached_sa" {
  account_id   = "${var.prefix}-memcached-sa"
  display_name = "${var.prefix} Service Account"
}

resource "google_project_iam_member" "memcached_compute_os_login_iam" {
  project = var.project_name
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.memcached_sa.email}"
}

resource "google_project_iam_member" "memcached_service_account_user_iam" {
  project = var.project_name
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.memcached_sa.email}"
}

resource "google_project_iam_member" "memcached_service_account_token_creator_iam" {
  project = var.project_name
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.memcached_sa.email}"
}

############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip_memcached" {
  count        = 2
  name         = "${var.prefix}-instance-internal-ip-${count.index + 1}"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gke_subnet.id      ###google_compute_subnetwork.gke_public_subnet.id
  address      = "10.10.0.${count.index + 20}"
}

##################################################### Firewall Rule for Memcached Server ########################################################

resource "google_compute_firewall" "firewall_rule_for_memcached_server" {
  name    = "allow-memcached-ingress"
  network = google_compute_network.gke_vpc.id  # Replace with your VPC network name

  allow {
    protocol = "tcp"
    ports    = ["11211"]
  }

  source_ranges = ["10.224.0.0/12", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20", "192.168.0.0/16" ]
  target_tags   = ["allow-memcached"] # Replace with your desired target tag
}

################################################ Create GCP Compute Engine VM instance ##########################################################

#resource "google_compute_address" "vm_static_ip_memcached" {
#  name         = "memcached-static-ip"
#  address_type = "EXTERNAL"
#  region       = "us-central1"  # Replace with your desired region
#  ip_version   = "IPV4"         # Default value is IPV4
#}

resource "google_compute_instance" "vm_instance_memcached" {
  count        = 2
  name         = "${var.prefix}-memcached-vm-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = "us-central1-b"
  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20260213"
      size  = 20
      type  = "pd-standard" ### Select among pd-standard, pd-balanced or pd-ssd.
      architecture = "X86_64"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.gke_subnet.id            ###google_compute_subnetwork.gke_public_subnet.id
    network_ip = google_compute_address.instance_internal_ip_memcached[count.index].address
#    access_config {
#      nat_ip = google_compute_address.vm_static_ip_memcached.address   ### Static IP Assigned to GCP VM Instance.
#    }
  }
  service_account {
    email = google_service_account.memcached_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("startup-memcached.sh")

  tags = ["allow-ssh", "allow-memcached"]

  depends_on = [google_compute_disk.persistent_disk_memcached]
}

resource "google_compute_disk" "persistent_disk_memcached" {
  count = 2
  name  = "${var.prefix}-persistent-disk-memcached-${count.index + 1}"
  type  = "pd-standard"
  zone  = "us-central1-b"
  size  = 20
}

resource "google_compute_attached_disk" "attach_persistent_disk_memcached" {
  count    = 2
  disk     = google_compute_disk.persistent_disk_memcached[count.index].id
  instance = google_compute_instance.vm_instance_memcached[count.index].id
}
