# Creación de una red DMZ
resource "google_compute_network" "dmz_vpc" {
  name                    = "dmz-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dmz_subnet" {
  name          = "dmz-subnet"
  ip_cidr_range = "10.0.5.0/24"
  region        = var.region
  network       = google_compute_network.dmz_vpc.id
}

# Regla de firewall para la red
resource "google_compute_firewall" "dmz_allow_ssh" {
  name    = "dmz-allow-ssh"
  network = google_compute_network.dmz_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22","80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


# Instancia en la Red
resource "google_compute_instance" "dmz_instance" {
  name         = "dmz-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  metadata = {
    ssh-keys = local.ssh_metadata
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
    sudo apt-get update
    sudo apt-get install -y python3-pip

  EOT

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.dmz_vpc.id
    subnetwork = google_compute_subnetwork.dmz_subnet.id

    access_config {
      # Esto asigna una IP pública efímera
    }
  }

}

# Configuration for network access translation (NAT) in GCP
resource "google_compute_router" "dmz" {
  name    = "dmz-router"
  network = google_compute_network.dmz_vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat_dmz" {
  name                               = "nat-dmz"
  router                             = google_compute_router.dmz.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Optional: Enable logging
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}