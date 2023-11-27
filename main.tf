terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.9.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.9.0"
    }
    
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

provider "google" {
  project = var.google_project
}

provider "google-beta" {
  project = var.google_project
}

data "google_compute_network" "tvg" {
  project = var.google_project
  name    = var.network_name
}

data "google_compute_subnetwork" "us-west-subnetwork" {
  project = var.google_project
  name    = "tvg-us-west1-subnet1"
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.loadtest-central.endpoint}"
  config_path            = "~/.kube/config"
  cluster_ca_certificate = base64decode(google_container_cluster.loadtest-central.master_auth.0.cluster_ca_certificate)
}

provider "vault" {
  address = "https://vault.gcp-dev.tvg.com"
}