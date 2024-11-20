resource "google_compute_health_check" "tcp_health_check" {
  name               = "tcp-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = 80  # Replace with the port your application listens on
  }
}

# Instance Group for Main Server
resource "google_compute_instance_group" "main_instance_group" {
  name        = "main-instance-group"
  zone        = var.zone  # Replace with your instance's zone
  network     = google_compute_network.internal_main_vpc.self_link
  instances   = [google_compute_instance.internal_main_instance.self_link]
}

# Instance Group for Replica Server
resource "google_compute_instance_group" "replica_instance_group" {
  name        = "replica-instance-group"
  zone        = var.zone  # Replace with your instance's zone
  network     = google_compute_network.internal_replica_vpc.self_link
  instances   = [google_compute_instance.internal_replica_instance.self_link]
}

resource "google_compute_backend_service" "internal_lb_backend" {
  name                  = "internal-lb-backend"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "TCP"
  health_checks         = [google_compute_health_check.tcp_health_check.id]
  timeout_sec           = 10

  backend {
    group = google_compute_instance_group.main_instance_group.id
  }

  backend {
    group = google_compute_instance_group.replica_instance_group.id
  }
}

resource "google_compute_address" "internal_lb_ip" {
  name          = "internal-lb-ip"
  address_type  = "INTERNAL"
  subnetwork    = google_compute_subnetwork.management_subnet.id  # Use the subnetwork where the load balancer resides
  region        = var.region
}

resource "google_compute_forwarding_rule" "internal_lb_forwarding_rule" {
  name                  = "internal-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_backend_service.internal_lb_backend.id
  ip_protocol           = "TCP"
  all_ports             = true  # Or specify a specific port using 'ports'
  ip_address            = google_compute_address.internal_lb_ip.address
  network               = google_compute_network.management_vpc.self_link
  subnetwork            = google_compute_subnetwork.management_subnet.self_link
  region                = var.region
}

# Allow clients to access the load balancer
resource "google_compute_firewall" "allow_client_to_lb" {
  name    = "allow-client-to-lb"
  network = google_compute_network.management_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]  # Replace with your application port
  }

  source_ranges = ["10.0.0.0/8"]  # Adjust the source range as needed
  target_tags   = ["allow-to-lb"]  # Apply this tag to clients
}

# Allow load balancer to communicate with instances
resource "google_compute_firewall" "allow_lb_to_instances" {
  name    = "allow-lb-to-instances"
  network = google_compute_network.management_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]  # Replace with your application port
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]  # GCP LB ranges
  target_tags   = ["allow-from-lb"]  # Apply this tag to instances
}
