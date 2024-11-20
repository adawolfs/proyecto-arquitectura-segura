resource "google_cloud_ids_endpoint" "ids_endpoint" {
  name             = "ids-endpoint"
  network          = google_compute_network.management_vpc.id
  location         = var.zone
  severity         = "INFORMATIONAL"
  threat_exceptions = []
  depends_on = [google_service_networking_connection.private_service_connection]
}
