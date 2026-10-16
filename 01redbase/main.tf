resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.loc
  tags     = var.tags
}

# NSGs
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_vm" {
  name                = "nsg-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_end" {
  name                = "nsg-end"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-tf4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags

  # Subred App Service (Delegada)
  subnet {
    name             = "snet-app"
    address_prefixes = ["10.0.1.0/24"]
    security_group   = azurerm_network_security_group.nsg_app.id
    delegation {
      name = "del-app"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }

  # Subred DB (con delegación para PostgreSQL Flexible Server)
  subnet {
    name             = "snet-db"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.nsg_db.id

    delegation {
      name = "del-pg"
      service_delegation {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }

  # Subred VM
  subnet {
    name             = "snet-vm"
    address_prefixes = ["10.0.3.0/24"]
    security_group   = azurerm_network_security_group.nsg_vm.id
  }

  # Subred Endpoints
  subnet {
    name             = "snet-end"
    address_prefixes = ["10.0.4.0/24"]
    security_group   = azurerm_network_security_group.nsg_end.id
  }

  # Subred Bastion (SIN NSG)
  subnet {
    name             = "AzureBastionSubnet"
    address_prefixes = ["10.0.5.0/24"]
  }
}