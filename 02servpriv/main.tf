data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# DNS Zones
resource "azurerm_private_dns_zone" "dns_pg" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Links
resource "azurerm_private_dns_zone_virtual_network_link" "link_pg" {
  name                 = "link-pg"
  private_dns_zone_id  = azurerm_private_dns_zone.dns_pg.id
  virtual_network_id   = data.azurerm_virtual_network.vnet.id
  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_blob" {
  name                 = "link-blob"
  private_dns_zone_id  = azurerm_private_dns_zone.dns_blob.id
  virtual_network_id   = data.azurerm_virtual_network.vnet.id
  registration_enabled = false
}

output "dns_pg_id" { value = azurerm_private_dns_zone.dns_pg.id }