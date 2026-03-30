########################################################## Datasource for GCP VPC and Subnet ###################################################

data "google_compute_network" "gitlab_vpc" {
  name    = var.gcp_vpc_name
}

data "google_compute_subnetwork" "gitlab_subnetwork" {
  name   = var.gcp_subnet_name
  region = var.gcp_region
}

######################################################### Firewall Rule for SSH ################################################################

resource "google_compute_firewall" "allow_port_22" {
  name    = "allow-ssh-ingress-gitlab"
  network = "projects/${var.project_name}/global/networks/${var.gcp_vpc_name}"    ###google_compute_network.gcp_vpc.id  

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh-gitlab"] # Replace with your desired target tag
}

######################################################### Firewall Rule for HTTPS ################################################################

resource "google_compute_firewall" "allow_port_443" {
  name    = "allow-https-ingress"
  network = "projects/${var.project_name}/global/networks/${var.gcp_vpc_name}"    ###google_compute_network.gcp_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-https"] # Replace with your desired target tag
}

######################################################## Firewall Rule to allow health check ######################################################

resource "google_compute_firewall" "allow_health_check_gitlab" {
  name          = "allow-health-check-gitlab"
  direction     = "INGRESS"
  network       = "projects/${var.project_name}/global/networks/${var.gcp_vpc_name}"   ###google_compute_network.gcp_vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]  ### Google uses specific IP ranges for its health check probes.
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check-gitlab"]
}

######################################################### Service Account in GCP ################################################################

resource "google_service_account" "multicloud_dexter_sa" {
  account_id   = "${var.prefix}-sa"
  display_name = "${var.prefix} Service Account"
}

resource "google_project_iam_member" "service_account_storage_permission" {
  project = var.project_name 
  role    = "roles/owner"   ###"roles/storage.admin"
  member  = "serviceAccount:${google_service_account.multicloud_dexter_sa.email}"
}

############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  name         = "${var.prefix}-instance-internal-ip"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = "projects/${var.project_name}/regions/${var.gcp_region}/subnetworks/${var.gcp_subnet_name}"###google_compute_subnetwork.gcp_public_subnet.id 
  address      = "10.20.15.100"
}

################################################### Create Compute Engine VM instances ##########################################################

resource "google_compute_address" "vm_static_ip" {
  name         = "gitlab-server-static-ip"
  address_type = "EXTERNAL"
  region       = var.gcp_region  # Replace with your desired region
  ip_version   = "IPV4"         # Default value is IPV4
}

data "google_compute_zones" "available" {

}

resource "google_compute_instance" "vm_instance" {
  name         = "gitlab-server"
  machine_type = var.machine_type[3]
  zone         = data.google_compute_zones.available.names[0]
  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20250610"
      size  = 20
      type  = "pd-standard" ### Select among pd-standard, pd-balanced or pd-ssd.
      architecture = "X86_64"
    }
  }
  network_interface {
    subnetwork = "projects/${var.project_name}/regions/${var.gcp_region}/subnetworks/${var.gcp_subnet_name}"###google_compute_subnetwork.gcp_public_subnet.id
    network_ip = google_compute_address.instance_internal_ip.address
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address   ### Static IP Assigned to GCP VM Instance.
    }
  }
  service_account {
    email = google_service_account.multicloud_dexter_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("startup-gitlab-server.sh")

  tags = ["allow-ssh-gitlab", "allow-health-check-gitlab"]
}

resource "null_resource" "gitlab_server" {

  provisioner "remote-exec" {
    inline = [
         "sleep 150",
         "sudo firewall-cmd --permanent --add-service=http",
         "sudo firewall-cmd --permanent --add-service=https",
         "sudo firewall-cmd --permanent --add-service=ssh",
         "sudo systemctl reload firewalld",
         "sudo yum install -y policycoreutils-python-utils openssh-server openssh-clients perl",
         "curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash",
         "sudo EXTERNAL_URL=\"http://gitlab.singhritesh85.com\" yum install -y gitlab-ee",
###      "sudo gitlab-ctl reconfigure",  ### Need to run when you do changes in /etc/gitlab/gitlab.rb
         "sudo gitlab-ctl start",
         "sudo gitlab-ctl status",
    ]
  }
  connection {
    type = "ssh"
    host = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
    user = "dexter"
    password = "Password@#795"
  }
  depends_on = [google_compute_instance.vm_instance]
}
