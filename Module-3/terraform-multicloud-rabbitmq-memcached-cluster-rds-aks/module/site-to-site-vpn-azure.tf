######################################### Azure VPN Gateway ###########################################

resource "azurerm_public_ip" "vnetgtw1_ip" {
  name                = "${var.prefix}-VNGTW1-ip"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  allocation_method   = var.static_dynamic[0]
 
  sku   = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard
  zones = [var.availability_zone]

  tags = {
    environment = var.env
  } 

}

resource "azurerm_public_ip" "vnetgtw2_ip" {
  name                = "${var.prefix}-VNGTW2-ip"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  allocation_method   = var.static_dynamic[0]

  sku   = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard
  zones = [var.availability_zone]

  tags = {
    environment = var.env
  }

}

resource "azurerm_virtual_network_gateway" "vnetgtw" {
  name                = "${var.prefix}-VNGTW"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true    ### High-availability configuration of the Azure Virtual Network Gateway
  bgp_enabled   = true
  sku           = "VpnGw2AZ"  ###"VpnGw1"
  generation    = "Generation2"

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.vnetgtw1_ip.id
    private_ip_address_allocation = var.static_dynamic[1]
    subnet_id                     = azurerm_subnet.vnet1_gtwsubnet.id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.vnetgtw2_ip.id
    private_ip_address_allocation = var.static_dynamic[1]
    subnet_id                     = azurerm_subnet.vnet1_gtwsubnet.id
  }

  bgp_settings {
    asn         = var.azure_bgp_asn
    peer_weight = 100

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses       = [cidrhost("169.254.21.0/30", 2), cidrhost("169.254.22.0/30", 2)]   ###["169.254.21.1"]
    }

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses       = [cidrhost("169.254.21.4/30", 2), cidrhost("169.254.22.4/30", 2)]   ###["169.254.22.1"]
    }
  }
}

################################## Local Network Gateway 1 ###########################################

resource "azurerm_local_network_gateway" "local_network_gtw_1" {
  count               = 2
  name                = "${var.prefix}-lngtw-1-${count.index + 1}"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  gateway_address     = count.index == 0 ? aws_vpn_connection.site2site_vpn_for_azure[0].tunnel1_address : aws_vpn_connection.site2site_vpn_for_azure[0].tunnel2_address
  bgp_settings {
    asn                 = var.aws_asn     ### ASN Same as AWS Transit Gateway
    bgp_peering_address = count.index == 0 ? cidrhost("169.254.21.0/30", 1) : cidrhost("169.254.22.0/30", 1)
#    bgp_peering_address = count.index == 0 ? aws_vpn_connection.site2site_vpn_for_azure[0].tunnel1_cgw_inside_address : aws_vpn_connection.site2site_vpn_for_azure[1].tunnel1_cgw_inside_address
  }
#  address_space       = [var.vpc_cidr]   ### AWS VPC CIDR

  tags = {
    environment = var.env
  }

}

################################## Local Network Gateway 2 ###########################################

resource "azurerm_local_network_gateway" "local_network_gtw_2" {
  count               = 2
  name                = "${var.prefix}-lngtw-2-${count.index + 1}"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  gateway_address     = count.index == 0 ? aws_vpn_connection.site2site_vpn_for_azure[1].tunnel1_address : aws_vpn_connection.site2site_vpn_for_azure[1].tunnel2_address
  bgp_settings {
    asn                 = var.aws_asn    ### ASN Same as AWS Transit Gateway
    bgp_peering_address = count.index == 0 ? cidrhost("169.254.21.4/30", 1) : cidrhost("169.254.22.4/30", 1)
#    bgp_peering_address = count.index == 0 ? aws_vpn_connection.site2site_vpn_for_azure[0].tunnel2_cgw_inside_address : aws_vpn_connection.site2site_vpn_for_azure[1].tunnel2_cgw_inside_address
  }
#  address_space       = [var.vpc_cidr]  ### AWS VPC CIDR

  tags = {
    environment = var.env
  }

}

################################## Azure Virtual Network Gateway Connection 1 ########################

resource "random_password" "vpn_secret_azure_tunnel1Instance0" {
  length  = 32
  special = false
  lower   = true
  upper   = true
  numeric = false
}

resource "random_password" "vpn_secret_azure_tunnel2Instance0" {
  length  = 32
  special = false
  lower   = true
  upper   = true
  numeric = false
}

resource "azurerm_virtual_network_gateway_connection" "connection1" {
  count               = 2
  name                = "${var.prefix}-connection1-${count.index + 1}"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vnetgtw.id
  local_network_gateway_id        = azurerm_local_network_gateway.local_network_gtw_1[count.index].id

  shared_key = count.index == 0 ? random_password.vpn_secret_azure_tunnel1Instance0.result : random_password.vpn_secret_azure_tunnel2Instance0.result ###aws_vpn_connection.site2site_vpn_for_azure[count.index].tunnel1_preshared_key          ### Shared Key for Tunnel 1

  bgp_enabled                      = true
  connection_protocol             = "IKEv2"

  tags = {
    environment = var.env
  }

}

################################## Azure Virtual Network Gateway Connection 2 ########################

resource "random_password" "vpn_secret_azure_tunnel1Instance1" {
  length  = 32
  special = false
  lower   = true
  upper   = true
  numeric = false
}

resource "random_password" "vpn_secret_azure_tunnel2Instance1" {
  length  = 32
  special = false
  lower   = true
  upper   = true
  numeric = false
}

resource "azurerm_virtual_network_gateway_connection" "connection2" {
  count               = 2
  name                = "${var.prefix}-connection2-${count.index + 1}"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vnetgtw.id
  local_network_gateway_id        = azurerm_local_network_gateway.local_network_gtw_2[count.index].id

  shared_key = count.index == 0 ? random_password.vpn_secret_azure_tunnel1Instance1.result : random_password.vpn_secret_azure_tunnel2Instance1.result ###aws_vpn_connection.site2site_vpn_for_azure[count.index].tunnel2_preshared_key         ### Shared Key for Tunnel 2

  bgp_enabled                      = true
  connection_protocol             = "IKEv2"

  tags = {
    environment = var.env
  }

}

################################### Azure to GCP Site to Site Connection ####################################

resource "azurerm_local_network_gateway" "gcp_gw1" {
  name                = "azure-to-gcp-local-network-gateway-1"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  gateway_address     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[0].ip_address
#  address_space       = ["10.10.0.0/20"]  ### Will be used in case of static routing

  bgp_settings {
    asn                 = var.gcp_asn   ### ASN Same as GCP Cloud Router
    bgp_peering_address = google_compute_router_peer.gcp_to_azure_router_peer[0].ip_address
  }
}

resource "azurerm_local_network_gateway" "gcp_gw2" {
  name                = "azure-to-gcp-local-network-gateway-2"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  gateway_address = google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[1].ip_address
#  address_space       = ["10.10.0.0/20"]  ### Will be used in case of static routing

  bgp_settings {
    asn                 = var.gcp_asn  ### ASN Same as GCP Cloud Router
    bgp_peering_address = google_compute_router_peer.gcp_to_azure_router_peer[1].ip_address
  }
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection1" {
  name                = "azure-to-gcp-vpn-connection-1"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.vnetgtw.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_gw1.id
  shared_key                 = random_password.vpn_secret_tunnel1.result

  bgp_enabled = true  ### For static Routing make it as false
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection2" {
  name                = "azure-to-gcp-vpn-connection-2"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.vnetgtw.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_gw2.id
  shared_key                 = random_password.vpn_secret_tunnel2.result

  bgp_enabled = true  ### For static Routing make it as false
}
