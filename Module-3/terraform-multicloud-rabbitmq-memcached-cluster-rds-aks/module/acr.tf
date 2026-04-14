resource "azurerm_container_registry" "acr" {
#  count                         = var.vm_count
  name                          = "${var.prefix}container24registry"
  resource_group_name           = azurerm_resource_group.vnetconnection_rg.name
  location                      = azurerm_resource_group.vnetconnection_rg.location
  sku                           = var.acr_sku
  public_network_access_enabled = false
  admin_enabled                 = var.admin_enabled
}

resource "azurerm_private_dns_zone" "acr_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link" {
  name                  = "${var.prefix}-acr-dns-link"
  resource_group_name   = azurerm_resource_group.vnetconnection_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet-1.id
}

resource "azurerm_private_endpoint" "acr_pe" {
  name                = "${var.prefix}-acr-private-endpoint"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  subnet_id           = azurerm_subnet.subnet_se.id

  private_service_connection {
    name                           = "${var.prefix}-acr-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns.id]
  }
}

#resource "azurerm_private_dns_a_record" "acr_record" {
#  name                = azurerm_container_registry.acr.name
#  zone_name           = azurerm_private_dns_zone.acr_dns.name
#  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
#  ttl                 = 300
#  records             = [azurerm_private_endpoint.acr_pe.private_service_connection[0].private_ip_address]
#}
