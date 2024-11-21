# Reglas de firewall para la DMZ
resource "google_compute_firewall" "dmz_allow_http_https" {
  name    = "dmz-allow-http-https"
  network = google_compute_network.dmz_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Reglas de firewall para la red interna main
resource "google_compute_firewall" "internal_main_allow_http_https" {
  name    = "internal-main-allow-http-https"
  network = google_compute_network.internal_main_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Reglas de firewall para la red interna replica
resource "google_compute_firewall" "internal_replica_allow_http_https" {
  name    = "internal-replica-allow-http-https"
  network = google_compute_network.internal_replica_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
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

# Permitir SSH desde el servidor de administración a internal_main_instance
resource "google_compute_firewall" "internal_main_allow_ssh_from_management" {
  name    = "internal-main-allow-ssh-from-management"
  network = google_compute_network.internal_main_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [google_compute_instance.management_instance.network_interface[0].network_ip]
}

# Permitir SSH desde el servidor de administración a internal_replica_instance
resource "google_compute_firewall" "internal_replica_allow_ssh_from_management" {
  name    = "internal-replica-allow-ssh-from-management"
  network = google_compute_network.internal_replica_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [google_compute_instance.management_instance.network_interface[0].network_ip]
}

# Permitir SSH desde el servidor de administración a dmz_instance
resource "google_compute_firewall" "dmz_allow_ssh_from_management" {
  name    = "dmz-allow-ssh-from-management"
  network = google_compute_network.dmz_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [google_compute_instance.management_instance.network_interface[0].network_ip]
}
