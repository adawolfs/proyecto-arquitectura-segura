data "google_project" "project" {
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager_api" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Enable SQL Admin API
resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Creates SQL instance (~15 minutes to fully spin up)
resource "google_sql_database_instance" "default" {
  name             = "mysql-instance-1"
  region           = var.region
  database_version = "MYSQL_8_0"
  root_password    = "abcABC123!"

  settings {
    tier = "db-f1-micro"
    password_validation_policy {
      min_length                  = 6
      complexity                  = "COMPLEXITY_DEFAULT"
      reuse_interval              = 2
      disallow_username_substring = true
      enable_password_policy      = true
    }
  }
  # set `deletion_protection` to true, will ensure that one cannot accidentally delete this instance by
  # use of Terraform whereas `deletion_protection_enabled` flag protects this instance at the GCP level.
  deletion_protection = false
  depends_on          = [google_project_service.sqladmin_api]
}


# Create dbuser secret
resource "google_secret_manager_secret" "dbuser" {
  secret_id = "dbusersecret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

# Attaches secret data for dbuser secret
resource "google_secret_manager_secret_version" "dbuser_data" {
  secret      = google_secret_manager_secret.dbuser.id
  secret_data = "secret-data" # Stores secret as a plain txt in state
}

# Update service account for dbuser secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbuser" {
  secret_id = google_secret_manager_secret.dbuser.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com" # Project's compute service account
}




# Create dbpass secret
resource "google_secret_manager_secret" "dbpass" {
  secret_id = "dbpasssecret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

# Attaches secret data for dbpass secret
resource "google_secret_manager_secret_version" "dbpass_data" {
  secret      = google_secret_manager_secret.dbpass.id
  secret_data = "secret-data" # Stores secret as a plain txt in state
}

# Update service account for dbpass secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbpass" {
  secret_id = google_secret_manager_secret.dbpass.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com" # Project's compute service account
}



# Create dbname secret
resource "google_secret_manager_secret" "dbname" {
  secret_id = "dbnamesecret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

# Attaches secret data for dbname secret
resource "google_secret_manager_secret_version" "dbname_data" {
  secret      = google_secret_manager_secret.dbname.id
  secret_data = "secret-data" # Stores secret as a plain txt in state
}

# Update service account for dbname secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbname" {
  secret_id = google_secret_manager_secret.dbname.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com" # Project's compute service account
}

data "google_secret_manager_secret_version" "dbuser" {
  secret = google_secret_manager_secret.dbuser.name
  version = "latest"
}

data "google_secret_manager_secret_version" "dbname" {
  secret = google_secret_manager_secret.dbname.name
  version = "latest"
}

data "google_secret_manager_secret_version" "dbpass" {
  secret = google_secret_manager_secret.dbpass.name
  version = "latest"
}
