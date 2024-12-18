# Variables para reutilización

variable "project_name" {
  default = "security-standards-group-4"
}

variable "region" {
  default = "us-west1"
}

variable "zone" {
  default = "us-west1-c"
}

# Variables para reutilización
variable "ssh_username" {
  default = "magister"  # Reemplaza con tu nombre de usuario
}

variable "ssh_public_key_file" {
  default = "./id_rsa.pub"
}

variable "ssh_private_key_file" {
  default = "./id_rsa"
}



locals {
  ssh_public_key = file(var.ssh_public_key_file)
  ssh_private_key = file(var.ssh_private_key_file)
  ssh_metadata   = "${var.ssh_username}:${local.ssh_public_key}"
}

# Configuración del proveedor de Google Cloud
provider "google" {
  project = var.project_name
  region  = var.region
  zone    = var.zone
}

# Agrega la clave pública a los metadatos del proyecto
resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = local.ssh_metadata
  }
}

# Enable APIs
resource "google_project_service" "logging_api" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring_api" {
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
}

# Enable Cloud Kubernetes Engine API
resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
}