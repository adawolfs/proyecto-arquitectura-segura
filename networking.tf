# Red Interna Principal
resource "google_compute_network" "internal_main_vpc" {
  name                    = "internal-main-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "internal_main_subnet" {
  name          = "internal-main-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.internal_main_vpc.id
}

# Red Interna Réplica
resource "google_compute_network" "internal_replica_vpc" {
  name                    = "internal-replica-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "internal_replica_subnet" {
  name          = "internal-replica-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.internal_replica_vpc.id
}

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

# Red DMZ
resource "google_compute_network" "dmz_vpc" {
  name                    = "dmz-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dmz_subnet" {
  name          = "dmz-subnet"
  ip_cidr_range = "10.0.4.0/24"
  region        = var.region
  network       = google_compute_network.dmz_vpc.id
}
