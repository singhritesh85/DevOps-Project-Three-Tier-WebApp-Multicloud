############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  name         = "${var.prefix}-instance-internal-ip"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gke_public_subnet.id 
  address      = "10.20.15.200"
}

############################################# Create a single Compute Engine VM instance ########################################################

resource "google_compute_address" "vm_static_ip" {
  name         = "gitlab-runner-static-ip"
  address_type = "EXTERNAL"
  region       = "us-central1"  # Replace with your desired region
  ip_version   = "IPV4"         # Default value is IPV4
}

resource "google_compute_instance" "vm_instance" {
  name         = "${var.prefix}-gitlab-runner"
  machine_type = "e2-small"   ###var.machine_type[0]
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20250610"
      size  = 20
      type  = "pd-standard" ### Select among pd-standard, pd-balanced or pd-ssd.
      architecture = "X86_64"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.gke_public_subnet.id
    network_ip = google_compute_address.instance_internal_ip.address
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address   ### Static IP Assigned to GCP VM Instance.
    }
  }
  service_account {
    email = google_service_account.gke_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("startup.sh")

  tags = ["allow-ssh"]

  depends_on = [google_compute_disk.persistent_disk]
}

resource "google_compute_disk" "persistent_disk" {
  name  = "${var.prefix}-persistent-disk"
  type  = "pd-standard"
  zone  = "us-central1-a"
  size  = 20
}

resource "google_compute_attached_disk" "attach_persistent_disk" {
  disk     = google_compute_disk.persistent_disk.id
  instance = google_compute_instance.vm_instance.id
}
