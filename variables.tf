variable "google_project" {
  type    = string
  default = "tvg-network"
}

variable "region" {
  description = "Region"
  default     = "us-west1"
}

variable "network_name" {
  description = "Network Name"
  default     = "tvg-us-west1"
}

variable "database_name" {
  description = "Database Name"
  default     = "infracost-postgres-poc"
}

variable "database_root_password" {
  description = "Database Root Password"
}

variable "database_version" {
  description = "Database Version"
  default     = "POSTGRES_15"
}

variable "database_tier" {
  description = "Database Tier"
  default     = "db-f1-micro"
}

variable "project" {
  default = "tvg-network"
}

variable "network" {
  default = "tvg-us-central1"
}

variable "subnet" {
  default = "tvg-us-central1-subnet1"
}