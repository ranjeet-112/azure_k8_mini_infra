environments = {
  dev = {
    location            = "East US"
    resource_group_name = "rg-dev-k8s"
    deploy_acr          = true
    clusters = {
      primary = {
        dns_prefix                = "dev-aks"
        kubernetes_version        = "1.34"
        default_node_count        = 2
        vm_size                   = "Standard_D2s_v3"
        oidc_issuer_enabled       = true
        workload_identity_enabled = true
        additional_node_pools = {
          workload = {
            node_count = 1
            vm_size    = "Standard_D2s_v3"
          }
        }
      }
    }
    tags = {
      Environment = "Development"
    }
  }
}
