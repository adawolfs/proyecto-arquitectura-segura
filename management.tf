
# Red de Administración
resource "google_compute_network" "management_vpc" {
  name                    = "management-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "management_subnet" {
  name          = "management-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.management_vpc.id
}

resource "google_compute_global_address" "private_service_access" {
  name          = "private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.management_vpc.self_link
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.management_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

# Regla de firewall para la red de administración
resource "google_compute_firewall" "management_allow_ssh" {
  name    = "management-allow-ssh"
  network = google_compute_network.management_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Configuracion de archivo de pruebas
locals {
  main_python = file("./sql_app/main.py")
}


# Instancia en la Red de Administración
resource "google_compute_instance" "management_instance" {
  name         = "management-instance"
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
    echo '${local.ssh_private_key}' > /home/${var.ssh_username}/.ssh/id_rsa
    chmod 600 /home/${var.ssh_username}/.ssh/id_rsa

  EOT

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.management_vpc.id
    subnetwork = google_compute_subnetwork.management_subnet.id

    access_config {
      # Esto asigna una IP pública efímera
    }
  }

}