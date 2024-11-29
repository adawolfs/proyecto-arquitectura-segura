resource "google_project_iam_binding" "logs_viewer_binding" {
  project = var.project_name
  role    = "roles/logging.viewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:guategeeks3d@gmail.com",
  ]
}

resource "google_project_iam_binding" "compute_viewer_binding" {
  project = var.project_name
  role    = "roles/compute.viewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:guategeeks3d@gmail.com",
  ]
}

resource "google_project_iam_binding" "ids_viewer_binding" {
  project = var.project_name
  role    = "roles/ids.viewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:guategeeks3d@gmail.com",
  ]
}


## Allow Kubernetes Engine View permissions
resource "google_project_iam_binding" "kubernetes_engine_viewer_binding" {
  project = var.project_name
  role    = "roles/container.viewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:pbarriosc1@miumg.edu.gt",
    "user:guategeeks3d@gmail.com",
  ]
}

## Allow Cloud SQL Viewer permissions
resource "google_project_iam_binding" "cloud_sql_viewer_binding" {
  project = var.project_name
  role    = "roles/cloudsql.viewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:pbarriosc1@miumg.edu.gt",
    "user:guategeeks3d@gmail.com",
  ]
}

## Allow Network Viewer permissions
resource "google_project_iam_binding" "firewall_viewer_binding" {
  project = var.project_name
  role    = "roles/compute.networkViewer"
  members = [
    "user:Adolfotop91@gmail.com",
    "user:Ludin777@gmail.com",
    "user:Julio.cloud.1989@gmail.com",
    "user:pbarriosc1@miumg.edu.gt",
    "user:guategeeks3d@gmail.com",
  ]
}