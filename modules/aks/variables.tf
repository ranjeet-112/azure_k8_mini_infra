variable "aks_clusters" {
  description = "Map of AKS clusters to create"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    dns_prefix          = string
    kubernetes_version  = optional(string)

    default_node_pool = object({
      name       = string
      node_count = number
      vm_size    = string
      upgrade_settings = optional(object({
        max_surge = string
      }))
    })

    identity = optional(object({
      type = string
    }), { type = "SystemAssigned" })

    oidc_issuer_enabled       = optional(bool, false)
    workload_identity_enabled = optional(bool, false)

    extra_node_pools = optional(map(object({
      vm_size    = string
      node_count = number
      mode       = optional(string, "User")
    })), {})

    network_profile = optional(object({
      network_plugin    = optional(string, "azure")
      load_balancer_sku = optional(string, "standard")
    }))
  }))
}
