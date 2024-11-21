# Regional Health Check
resource "google_compute_region_health_check" "tcp_health_check" {
  name               = "tcp-health-check"
  region             = var.region
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = 80
  }
}

# Instance Groups (Unmanaged)
resource "google_compute_instance_group" "main_instance_group" {
  name      = "main-instance-group"
  zone      = var.zone
  instances = [google_compute_instance.internal_main_instance.self_link]
}

resource "google_compute_instance_group" "replica_instance_group" {
  name      = "replica-instance-group"
  zone      = var.zone
  instances = [google_compute_instance.internal_replica_instance.self_link]
}

# Regional Backend Service
resource "google_compute_region_backend_service" "internal_lb_backend" {
  name                  = "internal-lb-backend"
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "TCP"
  health_checks         = [google_compute_region_health_check.tcp_health_check.id]
  timeout_sec           = 10

  backend {
    group = google_compute_instance_group.main_instance_group.self_link
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 100  # Adjust this value as needed
  }

  backend {
    group = google_compute_instance_group.replica_instance_group.self_link
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 100  # Adjust this value as needed
  }
}

# Internal IP Address
resource "google_compute_address" "internal_lb_ip" {
  name         = "internal-lb-ip"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.management_subnet.id
  region       = var.region
}

# Forwarding Rule
resource "google_compute_forwarding_rule" "internal_lb_forwarding_rule" {
  name                  = "internal-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  backend_service       = google_compute_region_backend_service.internal_lb_backend.self_link
  ip_protocol           = "TCP"
  ports                 = ["80"]
  ip_address            = google_compute_address.internal_lb_ip.address
  network               = google_compute_network.management_vpc.self_link
  subnetwork            = google_compute_subnetwork.management_subnet.self_link
  region                = var.region
}

# Firewall Rules
resource "google_compute_firewall" "allow_client_to_lb" {
  name    = "allow-client-to-lb"
  network = google_compute_network.management_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.0.0.0/8"]  # Adjust as needed
  target_tags   = ["allow-to-lb"]
}

resource "google_compute_firewall" "allow_lb_to_instances" {
  name    = "allow-lb-to-instances"
  network = google_compute_network.management_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]  # GCP internal LB ranges
  target_tags   = ["allow-from-lb"]
}
