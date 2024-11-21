# Configuration for network access translation (NAT) in GCP
resource "google_compute_router" "nat_router_main" {
  name    = "nat-router-main"
  network = google_compute_network.internal_main_vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat_main" {
  name                               = "nat-main"
  router                             = google_compute_router.nat_router_main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Optional: Enable logging
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Configuration for network access translation (NAT) in GCP
resource "google_compute_router" "nat_router_replica" {
  name    = "nat-router-replica"
  network = google_compute_network.internal_replica_vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat_replica" {
  name                               = "nat-replica"
  router                             = google_compute_router.nat_router_replica.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Optional: Enable logging
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}