# VPC Peering entre management_vpc y internal_main_vpc
resource "google_compute_network_peering" "management_to_internal_main" {
  name         = "management-to-internal-main"
  network      = google_compute_network.management_vpc.id
  peer_network = google_compute_network.internal_main_vpc.id
}

resource "google_compute_network_peering" "internal_main_to_management" {
  name         = "internal-main-to-management"
  network      = google_compute_network.internal_main_vpc.id
  peer_network = google_compute_network.management_vpc.id
}

# VPC Peering entre management_vpc y internal_replica_vpc
resource "google_compute_network_peering" "management_to_internal_replica" {
  name         = "management-to-internal-replica"
  network      = google_compute_network.management_vpc.id
  peer_network = google_compute_network.internal_replica_vpc.id
}

resource "google_compute_network_peering" "internal_replica_to_management" {
  name         = "internal-replica-to-management"
  network      = google_compute_network.internal_replica_vpc.id
  peer_network = google_compute_network.management_vpc.id
}

# VPC Peering entre management_vpc y dmz_vpc
resource "google_compute_network_peering" "management_to_dmz" {
  name         = "management-to-dmz"
  network      = google_compute_network.management_vpc.id
  peer_network = google_compute_network.dmz_vpc.id
}

resource "google_compute_network_peering" "dmz_to_management" {
  name         = "dmz-to-management"
  network      = google_compute_network.dmz_vpc.id
  peer_network = google_compute_network.management_vpc.id
}
