resource "azurerm_kubernetes_cluster" "aks" {
  for_each = var.aks_clusters

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.kubernetes_version

  default_node_pool {
    name       = each.value.default_node_pool.name
    node_count = each.value.default_node_pool.node_count
    vm_size    = each.value.default_node_pool.vm_size

    dynamic "upgrade_settings" {
      for_each = each.value.default_node_pool.upgrade_settings != null ? [each.value.default_node_pool.upgrade_settings] : []
      content {
        max_surge = upgrade_settings.value.max_surge
      }
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
    }
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin    = network_profile.value.network_plugin
      load_balancer_sku = network_profile.value.load_balancer_sku
    }
  }
}

# Nested loop logic for extra node pools
locals {
  extra_node_pools_flat = flatten([
    for cluster_key, cluster in var.aks_clusters : [
      for pool_key, pool in cluster.extra_node_pools : {
        cluster_key = cluster_key
        pool_key    = pool_key
        cluster_id  = azurerm_kubernetes_cluster.aks[cluster_key].id
        vm_size     = pool.vm_size
        node_count  = pool.node_count
        mode        = pool.mode
      }
    ]
  ])
}

resource "azurerm_kubernetes_cluster_node_pool" "extra" {
  for_each = {
    for pool in local.extra_node_pools_flat : "${pool.cluster_key}.${pool.pool_key}" => pool
  }

  name                  = each.value.pool_key
  kubernetes_cluster_id = each.value.cluster_id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  mode                  = each.value.mode
}

output "aks_ids" {
  value = { for k, v in azurerm_kubernetes_cluster.aks : k => v.id }
}

output "kube_configs" {
  value     = { for k, v in azurerm_kubernetes_cluster.aks : k => v.kube_config_raw }
  sensitive = true
}
