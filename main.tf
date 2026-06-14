# 1. Resource Group Module
module "resource_groups" {
  source = "./modules/resource_group"

  resource_groups = {
    for env_key, env in var.environments : env_key => {
      name     = env.resource_group_name
      location = env.location
      tags     = env.tags
    }
  }
}

# 2. ACR Module (Conditional Iteration)
module "acr" {
  source = "./modules/acr"

  # Only pass registries where deploy_acr is true
  registries = {
    for env_key, env in var.environments : env_key => {
      name                = "acrdevk8s0614" # More unique stable name
      resource_group_name = module.resource_groups.resource_group_names[env_key]
      location            = module.resource_groups.resource_group_locations[env_key]
      sku                 = env.acr_sku
    }
    if env.deploy_acr
  }

  depends_on = [module.resource_groups]
}

# 3. AKS Module (Nested Mapping and logic)
module "aks" {
  source = "./modules/aks"

  aks_clusters = merge([
    for env_key, env in var.environments : {
      for cluster_key, cluster in env.clusters : "${env_key}-${cluster_key}" => {
        name                = "aks-${env_key}-${cluster_key}"
        resource_group_name = module.resource_groups.resource_group_names[env_key]
        location            = module.resource_groups.resource_group_locations[env_key]
        dns_prefix          = cluster.dns_prefix
        kubernetes_version  = cluster.kubernetes_version

        oidc_issuer_enabled       = cluster.oidc_issuer_enabled
        workload_identity_enabled = cluster.workload_identity_enabled

        default_node_pool = {
          name       = "default"
          node_count = cluster.default_node_count
          vm_size    = cluster.vm_size
        }

        extra_node_pools = {
          for pool_key, pool in cluster.additional_node_pools : pool_key => {
            vm_size    = pool.vm_size
            node_count = pool.node_count
          }
        }
      }
    }
  ]...)

  depends_on = [module.resource_groups]
}

output "env_acr_logins" {
  value = module.acr.acr_login_servers
}

output "env_aks_ids" {
  value = module.aks.aks_ids
}
