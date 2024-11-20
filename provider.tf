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

locals {
  ssh_public_key = file(var.ssh_public_key_file)
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