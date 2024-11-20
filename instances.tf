# Instancia en la Red Interna Principal
resource "google_compute_instance" "internal_main_instance" {
  name         = "internal-main-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  metadata = {
    ssh-keys = local.ssh_metadata
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.internal_main_vpc.id
    subnetwork = google_compute_subnetwork.internal_main_subnet.id
  }

  tags = ["allow-from-lb"]
}

# Instancia en la Red Interna Réplica
resource "google_compute_instance" "internal_replica_instance" {
  name         = "internal-replica-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  metadata = {
    ssh-keys = local.ssh_metadata
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.internal_replica_vpc.id
    subnetwork = google_compute_subnetwork.internal_replica_subnet.id
  }

  tags = ["allow-from-lb"]
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

# Instancia en la Red DMZ
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
