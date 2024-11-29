resource "google_compute_network" "cluster_network" {
  name = "cluster-network"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}

resource "google_compute_subnetwork" "cluster_subnetwork" {
  name = "cluster-subnetwork"

  ip_cidr_range = "10.10.0.0/16"
  region        = var.region

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL" # Change to "EXTERNAL" if creating an external loadbalancer

  network = google_compute_network.cluster_network.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }
}

resource "google_container_cluster" "default" {
  name = "main-autopilot-cluster"

  location                 = var.region
  enable_autopilot         = true
  enable_l4_ilb_subsetting = true

  network    = google_compute_network.cluster_network.id
  subnetwork = google_compute_subnetwork.cluster_subnetwork.id

  ip_allocation_policy {
    stack_type                    = "IPV4_IPV6"
    services_secondary_range_name = google_compute_subnetwork.cluster_subnetwork.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.cluster_subnetwork.secondary_ip_range[1].range_name
  }

  # Set `deletion_protection` to `true` will ensure that one cannot
  # accidentally delete this instance by use of Terraform.
  deletion_protection = false

  depends_on = [ google_project_service.container_api ]
}

# VPC Peering entre management_vpc y internal_main_vpc
resource "google_compute_network_peering" "management_to_cluster_main" {
  name         = "management-to-cluster"
  network      = google_compute_network.management_vpc.id
  peer_network = google_compute_network.cluster_network.id
}

resource "google_compute_network_peering" "cluster_main_to_management" {
  name         = "cluster-to-management"
  network      = google_compute_network.cluster_network.id
  peer_network = google_compute_network.management_vpc.id
}

# Allow traffic from management subnet to cluster subnet
resource "google_compute_firewall" "allow_management_to_cluster" {
  name    = "allow-management-to-cluster"
  network = google_compute_network.cluster_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [google_compute_instance.management_instance.network_interface[0].network_ip]
}

# Allow traffic from cluster subnet to management subnet
resource "google_compute_firewall" "allow_cluster_to_management" {
  name    = "allow-cluster-to-management"
  network = google_compute_network.cluster_network.id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.10.0.0/16"] # Cluster subnet CIDR
  destination_ranges = ["10.0.3.0/24"] # Management subnet CIDR
}
