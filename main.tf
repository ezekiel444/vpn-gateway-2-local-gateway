
resource "azurerm_resource_group" "rg" {
  name     = "perso_Matomi"
  location = "west europe"
}
resource "azurerm_virtual_network" "vnet" {
  name                = "emlvnet-postgresql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

/* resource "azurerm_network_security_group" "nsg" {
  name                = "emlnsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "control-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
} */

resource "azurerm_subnet" "subnet-postgresql" {
  name                 = "emlsubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
   address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "gatewaysubnet-vnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "ip-vnet" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

/* resource "azurerm_subnet_network_security_group_association" "nsg-associate" {
  subnet_id                 = azurerm_subnet.subnet-postgresql.id
  network_security_group_id = azurerm_network_security_group.nsg.id
} */


resource "azurerm_private_dns_zone" "private-dns" {
  name                = "emlpostgresqldns.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatedns-link" {
  name                  = "postgresqlprivatednslink"
  private_dns_zone_name = azurerm_private_dns_zone.private-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
  registration_enabled = true
  depends_on = [ azurerm_private_dns_zone.private-dns ]
}


resource "azurerm_postgresql_flexible_server" "server" {
  name                   = "emlserverproject"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "14"
  delegated_subnet_id    = azurerm_subnet.subnet-postgresql.id
  private_dns_zone_id    = azurerm_private_dns_zone.private-dns.id
  administrator_login    = "eml"
  administrator_password = "Simplon12345."
  zone                   = "2"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.privatedns-link ]
}