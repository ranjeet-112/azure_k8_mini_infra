variable "environments" {
  description = "Nested map for infrastructure configuration"
  type = map(object({
    location            = string
    resource_group_name = string
    
    # Conditional ACR
    deploy_acr = optional(bool, false)
    acr_sku    = optional(string, "Standard")

    # AKS Clusters
    clusters = optional(map(object({
      dns_prefix = string
      kubernetes_version = optional(string, "1.27")
      default_node_count = optional(number, 2)
      vm_size           = optional(string, "Standard_D2s_v3")
      
      # Nested map for extra pools
      additional_node_pools = optional(map(object({
        node_count = number
        vm_size    = optional(string, "Standard_D2s_v3")
      })), {})
    })), {})

    tags = optional(map(string), {})
  }))
  
  default = {
    dev = {
      location            = "East US"
      resource_group_name = "rg-dev-k8s"
      deploy_acr          = true
      clusters = {
        primary = {
          dns_prefix = "dev-aks"
          additional_node_pools = {
            workload = {
              node_count = 1
            }
          }
        }
      }
      tags = {
        Environment = "Development"
      }
    }
  }
}
