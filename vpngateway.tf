
/* resource "azurerm_virtual_network" "vnet-gateway" {
  name                = "vnet-gateway"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet-vnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-gateway.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "ip-vnet" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
} */

resource "azurerm_virtual_network_gateway" "net-gateway" {
  name                  = "vpngatewayeml"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  type                  = "Vpn"
  vpn_type              = "RouteBased"
  sku                   = "VpnGw1"

  ip_configuration {
     name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.gatewaysubnet-vnet.id
    public_ip_address_id = azurerm_public_ip.ip-vnet.id
  }

}

resource "azurerm_local_network_gateway" "local-gateway" {
  name                = "localgatewayeml"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  gateway_address = "20.229.100.14"
  address_space       = ["10.2.0.0/16"]  # Replace with your actual address space
}


resource "azurerm_virtual_network_gateway_connection" "connection" {
  name                = "globalvpnconnection"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.net-gateway.id

  type = "IPsec"
  shared_key          = "Simplon12345."
  connection_protocol = "IKEv2"

  local_network_gateway_id = azurerm_local_network_gateway.local-gateway.id

  depends_on = [
    azurerm_virtual_network_gateway.net-gateway
  ]
}