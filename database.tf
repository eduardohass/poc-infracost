
resource "google_sql_database_instance" "postgres" {
  name             = var.database_name
  database_version = var.database_version
  region           = var.region
  root_password    = var.database_root_password

  settings {
    tier = "db-g1-micro"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.tvg.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}
