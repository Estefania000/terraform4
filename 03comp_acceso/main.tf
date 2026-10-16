data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = "vnet-tf4"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Subredes
data "azurerm_subnet" "snet_app" {
  name                 = "snet-app"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet_db" {
  name                 = "snet-db"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet_vm" {
  name                 = "snet-vm"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet_end" {
  name                 = "snet-end"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet_bast" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# 1. App Service (Linux)
resource "azurerm_service_plan" "asp" {
  name                = "asp-tf4"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-tf4-001"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on              = false
    vnet_route_all_enabled = true
  }

  virtual_network_subnet_id = data.azurerm_subnet.snet_app.id
}

# 2. Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "satf4estefania2026"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. PostgreSQL Flexible Server (Private Endpoint capable)
resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "pg-tf4-001"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  version                = "13"
  administrator_login    = "adminuser"
  administrator_password = "Password1234!"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"

  public_network_access_enabled = true
  # SIN delegated_subnet_id
  # SIN private_dns_zone_id
}

# 4. Private Endpoints
resource "azurerm_private_endpoint" "pe_pg" {
  name                = "pe-pg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.snet_end.id

  private_service_connection {
    name                           = "psc-pg"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
}

resource "azurerm_private_endpoint" "pe_blob" {
  name                = "pe-blob"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.snet_end.id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# 5. VM Linux (Worker)
resource "azurerm_network_interface" "nic_vm" {
  name                = "nic-vm-tf4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.snet_vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-tf4"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic_vm.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# 6. Azure Bastion
resource "azurerm_public_ip" "pip_bast" {
  name                = "pip-bast-tf4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bast" {
  name                = "bast-tf4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "config"
    subnet_id            = data.azurerm_subnet.snet_bast.id
    public_ip_address_id = azurerm_public_ip.pip_bast.id
  }
}