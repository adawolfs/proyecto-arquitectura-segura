
# VPC network
resource "google_compute_network" "default" {
  name                    = "l7-ilb-network"
  auto_create_subnetworks = false
}

# Proxy-only subnet
resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "l7-ilb-proxy-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.default.id
}

# Backend subnet
resource "google_compute_subnetwork" "default" {
  name          = "l7-ilb-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.default.id
}

# Permitir SSH desde el servidor de administración a internal_main_instance
resource "google_compute_firewall" "allow_ssh_from_management" {
  name    = "l7-ilb-subnet-allow-ssh-from-management"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [google_compute_instance.management_instance.network_interface[0].network_ip]
}

# Reglas de firewall para la red interna main
resource "google_compute_firewall" "l7_ilb_subnet_allow_http_https" {
  name    = "l7-ilb-subnet-allow-http-https"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "l7_ilb_subnet_allow_egress_http_https" {
  name    = "l7-ilb-subnet-allow-egress-http-https"
  network = google_compute_network.default.id
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# VPC Peering entre management_vpc y internal_main_vpc
resource "google_compute_network_peering" "management_to_internal_main" {
  name         = "management-to-l7-ilb"
  network      = google_compute_network.management_vpc.id
  peer_network = google_compute_network.default.id
}

resource "google_compute_network_peering" "internal_main_to_management" {
  name         = "l7-ilb-to-management"
  network      = google_compute_network.default.id
  peer_network = google_compute_network.management_vpc.id
}

# Configuration for network access translation (NAT) in GCP
resource "google_compute_router" "default" {
  name    = "l7-ilb-router"
  network = google_compute_network.default.name
  region  = var.region
}


# Reserved internal address
resource "google_compute_address" "default" {
  name         = "l7-ilb-ip"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  address      = "10.0.1.5"
  region       = var.region
  purpose      = "SHARED_LOADBALANCER_VIP"
}

# Regional forwarding rule
resource "google_compute_forwarding_rule" "default" {
  name                  = "l7-ilb-forwarding-rule"
  region                = var.region
  depends_on            = [google_compute_subnetwork.proxy_subnet]
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.default.id
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.default.id
  network               = google_compute_network.default.id
  subnetwork            = google_compute_subnetwork.default.id
  network_tier          = "PREMIUM"
}

# Self-signed regional SSL certificate for testing
resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["example.com"]

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "google_compute_region_ssl_certificate" "default" {
  name_prefix = "my-certificate-"
  private_key = tls_private_key.default.private_key_pem
  certificate = tls_self_signed_cert.default.cert_pem
  region      = var.region
  lifecycle {
    create_before_destroy = true
  }
}

# Regional target HTTPS proxy
resource "google_compute_region_target_https_proxy" "default" {
  name             = "l7-ilb-target-https-proxy"
  region           = var.region
  url_map          = google_compute_region_url_map.https_lb.id
  ssl_certificates = [google_compute_region_ssl_certificate.default.self_link]
}

# Regional URL map
resource "google_compute_region_url_map" "https_lb" {
  name            = "l7-ilb-regional-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.default.id
}

# Regional backend service
resource "google_compute_region_backend_service" "default" {
  name                  = "l7-ilb-backend-service"
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http-server"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.default.id]
  backend {
    group           = google_compute_region_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# Instance template
resource "google_compute_instance_template" "default" {
  name         = "l7-ilb-mig-template"
  machine_type = "e2-small"
  tags         = ["http-server"]
  
  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
    # access_config {
    #   # add external ip to fetch packages
    # }
  }
  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  # install nginx and serve a simple web page
  metadata = {
    ssh-keys = local.ssh_metadata
    startup-script = <<-EOF1
      #! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y nginx-light jq

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")

      cat <<EOF > /var/www/html/index.html
      <pre>
      Name: $NAME
      IP: $IP
      </pre>
      EOF
    EOF1
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Regional health check
resource "google_compute_region_health_check" "default" {
  name   = "l7-ilb-hc"
  region = var.region
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# Regional MIG1
resource "google_compute_region_instance_group_manager" "default" {
  name   = "l7-ilb-mig1"
  region = var.region
  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  named_port {
    name = "http-server"
    port = 80
  }
  base_instance_name = "vm"
  target_size        = 2
}

# Allow all access to health check ranges
resource "google_compute_firewall" "default" {
  name          = "l7-ilb-fw-allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.default.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}

# Allow http from proxy subnet to backends
resource "google_compute_firewall" "backends" {
  name          = "l7-ilb-fw-allow-ilb-to-backends"
  direction     = "INGRESS"
  network       = google_compute_network.default.id
  source_ranges = ["10.0.0.0/24"]
  target_tags   = ["http-server"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}

### HTTP-to-HTTPS redirect ###

# Regional forwarding rule
# resource "google_compute_forwarding_rule" "redirect" {
#   name                  = "l7-ilb-redirect"
#   region                = var.region
#   ip_protocol           = "TCP"
#   ip_address            = google_compute_address.default.id # Same as HTTPS load balancer
#   load_balancing_scheme = "INTERNAL_MANAGED"
#   port_range            = "80"
#   target                = google_compute_region_target_http_proxy.default.id
#   network               = google_compute_network.default.id
#   subnetwork            = google_compute_subnetwork.default.id
#   network_tier          = "PREMIUM"
# }

# Regional HTTP proxy
# resource "google_compute_region_target_http_proxy" "default" {
#   name    = "l7-ilb-target-http-proxy"
#   region  = var.region
#   url_map = google_compute_region_url_map.redirect.id
# }

# Regional URL map
# resource "google_compute_region_url_map" "redirect" {
#   name            = "l7-ilb-redirect-url-map"
#   region          = var.region
#   default_service = google_compute_region_backend_service.default.id
#   host_rule {
#     hosts        = ["*"]
#     path_matcher = "allpaths"
#   }

#   path_matcher {
#     name            = "allpaths"
#     default_service = google_compute_region_backend_service.default.id
#     path_rule {
#       paths = ["/"]
#       url_redirect {
#         https_redirect         = true
#         host_redirect          = "10.0.1.5:443"
#         redirect_response_code = "PERMANENT_REDIRECT"
#         strip_query            = true
#       }
#     }
#   }
# }

# Frontend instance template
resource "google_compute_instance_template" "frontend_template" {
  name         = "frontend-template"
  machine_type = "e2-small"
  tags         = ["frontend"]

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  # Install Nginx and configure to communicate with backend
  metadata = {
    ssh-keys = local.ssh_metadata
    startup-script = <<-EOF
      #!/bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive

      apt-get update
      apt-get install -y nginx
    EOF
  }
}

# Frontend managed instance group
resource "google_compute_region_instance_group_manager" "frontend_mig" {
  name               = "frontend-mig"
  region             = var.region
  base_instance_name = "frontend-vm"

  version {
    instance_template = google_compute_instance_template.frontend_template.id
  }

  named_port {
    name = "http-server"
    port = 80
  }

  target_size = 2
}

# Frontend health check
resource "google_compute_region_health_check" "frontend_health_check" {
  name   = "frontend-hc"
  region = var.region

  http_health_check {
    port = 80
  }
}

# Frontend backend service
resource "google_compute_region_backend_service" "frontend_backend_service" {
  name                  = "frontend-backend-service"
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http-server"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.frontend_health_check.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_instance_group_manager.frontend_mig.instance_group
    capacity_scaler = 1.0
  }
}

# Frontend URL map
resource "google_compute_region_url_map" "frontend_url_map" {
  name            = "frontend-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.frontend_backend_service.id
}

# Frontend HTTP proxy
resource "google_compute_region_target_http_proxy" "frontend_http_proxy" {
  name    = "frontend-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.frontend_url_map.id
}

# Frontend external IP address
resource "google_compute_address" "frontend_lb_ip" {
  name   = "frontend-lb-ip"
  region = var.region
}

# Frontend forwarding rule
resource "google_compute_forwarding_rule" "frontend_forwarding_rule" {
  name                  = "frontend-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.frontend_lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.frontend_http_proxy.id
  network               = google_compute_network.default.id
  network_tier          = "PREMIUM"
}

# Firewall rule to allow traffic from the load balancer to frontend instances
resource "google_compute_firewall" "frontend_allow_http" {
  name    = "frontend-allow-http"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["frontend"]
}

# Firewall rule to allow health checks
resource "google_compute_firewall" "frontend_allow_health_checks" {
  name          = "frontend-allow-health-checks"
  network       = google_compute_network.default.id
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["frontend"]
}

resource "google_compute_global_address" "main_private_service_access" {
  name          = "main-private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.default.self_link
}

resource "google_service_networking_connection" "main_private_service_connection" {
  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.main_private_service_access.name]
}