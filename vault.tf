module "kubernetes-vault" {
  depends_on = [google_container_cluster.loadtest-central]
  source     = "git::ssh://git@github.com/fanduel/racing-tvg-terraform-modules.git//vault/kubernetes-auth?ref=v1.5.8"

  cluster_endpoint                  = "https://${google_container_cluster.loadtest-central.endpoint}"
  auth_path                         = "kubernetes-loadtest-${var.region}"
  bound_service_accounts            = ["*"]
  bound_service_accounts_namespaces = ["ops","vault"]
  token_policies                    = ["services_k8s"]
}