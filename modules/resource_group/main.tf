resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

output "resource_group_names" {
  value = { for k, v in azurerm_resource_group.rg : k => v.name }
}

output "resource_group_locations" {
  value = { for k, v in azurerm_resource_group.rg : k => v.location }
}
