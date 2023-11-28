data "google_compute_subnetwork" "subnet" {
  project  = var.project
  provider = google-beta
  name     = var.subnet
  region   = var.region
}

resource "google_container_cluster" "loadtest-central" {
  project            = var.project
  name               = "loadtest-central1"
  location           = "us-central1-a"
  network            = var.network
  subnetwork         = data.google_compute_subnetwork.subnet.name
  min_master_version = "1.20"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  initial_node_count = 1

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  resource_labels = {
    gke-cluster = "loadtest"
  }

  # Setting an empty username and password explicitly disables basic auth
  # master_auth {
  #   username = ""
  #   password = ""
  # }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.32/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      #we need to enable access from everywhere because we do split tunneling
      cidr_block   = "0.0.0.0/0"
      display_name = "everywhere"
    }
  }
}

resource "google_container_node_pool" "monitoring-nodes" {
  project    = var.project
  name       = "monitoring-nodes"
  location   = "us-central1-a"
  cluster    = google_container_cluster.loadtest-central.name

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    max_node_count = 10
    min_node_count = 1
  }


  node_config {
    #save them big bucks
    preemptible = false
    labels = {
      "monitoring" = "true"
    }

    tags = [
      "loadtest",
      "monitoring"
    ]

    taint {
      key = "workloadType"
      value = "monitoring"
      effect = "NO_SCHEDULE"
    }
    
    machine_type = "n1-standard-32"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


resource "google_container_node_pool" "qa-loadtest-istio" {
  project  = var.project
  name     = "qa-testing-istio"
  location = "us-central1-a"
  cluster  = google_container_cluster.loadtest-central.name



  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    max_node_count = 7
    min_node_count = 0
  }


  node_config {
    # save them big bucks
    preemptible = false
    labels = {
      istio = "true"
    }

    #we don't want to have to scale nodes mid test
    machine_type = "n1-standard-8"

    tags = [
      "istio-loadtest"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    taint {
      key = "workloadType"
      value = "istio"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "qa-loadtest" {
  provider = google-beta

  project  = var.project
  name     = "qa-loadtest"
  location = "us-central1-a"
  cluster  = google_container_cluster.loadtest-central.name



  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    max_node_count = 100
    min_node_count = 0
  }


  node_config {
    # save them big bucks
    preemptible = false
    labels = {
      grid = "true"
    }

    #we don't want to have to scale nodes mid test
    machine_type = "n2-standard-128"

    tags = [
      "grid"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    linux_node_config {
      sysctls = {
        "net.ipv4.tcp_tw_reuse" = "1"
      }
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }
}

resource "google_dns_record_set" "kiali-dns" {
  project = var.project
  name    = "kiali-loadtest.gcp-dev.tvg.com."
  type    = "A"
  ttl     = 30

  managed_zone = "gcp-dev-tvg-com"

  rrdatas = ["10.226.1.112"]
}

resource "google_dns_record_set" "kiali-dns-private" {
  project = var.project
  name    = "kiali-loadtest.gcp-dev.tvg.com."
  type    = "A"
  ttl     = 30

  managed_zone = "gcp-dev-tvg-com-private"

  rrdatas = ["10.226.1.112"]
}


resource "google_dns_record_set" "jaegger-dns" {
  project = var.project
  name    = "jaegger-loadtest.gcp-dev.tvg.com."
  type    = "CNAME"
  ttl     = 300

  managed_zone = "gcp-dev-tvg-com"

  rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
}

# resource "google_dns_record_set" "selenium-dns" {
#   project = var.project
#   name    = "selenium-loadtest.gcp-dev.tvg.com."
#   type    = "CNAME"
#   ttl     = 300

#   managed_zone = "gcp-dev-tvg-com"

#   rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
# }

# resource "google_dns_record_set" "selenium4-dns" {
#   project = var.project
#   name    = "selenium4-loadtest.gcp-dev.tvg.com."
#   type    = "CNAME"
#   ttl     = 5

#   managed_zone = "gcp-dev-tvg-com"

#   rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
# }


resource "google_dns_record_set" "service-dev-dns-private" {
  project = var.project
  name    = "service-dev.gcp-dev.tvg.com."
  type    = "CNAME"
  ttl     = 300

  managed_zone = "gcp-dev-tvg-com-private"

  rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
}

resource "google_dns_record_set" "service-dev-dns" {
  project = var.project
  name    = "service-dev.gcp-dev.tvg.com."
  type    = "CNAME"
  ttl     = 300

  managed_zone = "gcp-dev-tvg-com"

  rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
}

resource "google_dns_record_set" "admin-dev-dns-private" {
  project = var.project
  name    = "admin-dev.gcp-dev.tvg.com."
  type    = "CNAME"
  ttl     = 300

  managed_zone = "gcp-dev-tvg-com-private"

  rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
}

resource "google_dns_record_set" "admin-dev-dns" {
  project = var.project
  name    = "admin-dev.gcp-dev.tvg.com."
  type    = "CNAME"
  ttl     = 300

  managed_zone = "gcp-dev-tvg-com"

  rrdatas = ["kiali-loadtest.gcp-dev.tvg.com."]
}