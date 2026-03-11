# AWS Customer Gateway for GCP
resource "aws_customer_gateway" "aws_cg" {
  count      = 2
  bgp_asn    = var.gcp_asn    ###65000
  ip_address = count.index == 0 ? google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[0].ip_address : google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "customer-gateway-${count.index + 1}"
  }
}

# AWS Customer Gateway for Azure
resource "aws_customer_gateway" "aws_cg_for_azure" {
  count      = 2
  bgp_asn    = var.azure_bgp_asn    ###65000
  ip_address = count.index == 0 ? azurerm_public_ip.vnetgtw1_ip.ip_address : azurerm_public_ip.vnetgtw2_ip.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "customer-gateway-for-azure-${count.index + 1}"
  }
}

# AWS Transit Gateway for GCP
resource "aws_ec2_transit_gateway" "custom_asn_tgw" {
  description                     = "AWS Transit Gateway to establish Site-to-Site VPN for GCP"
  amazon_side_asn                 = var.aws_asn
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = "asn-transit-gtw-gcp"
  }
}

# AWS Transit Gateway Attachment to VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment_to_tgw" {
  subnet_ids         = aws_subnet.private_subnet.*.id
  transit_gateway_id = aws_ec2_transit_gateway.custom_asn_tgw.id
  vpc_id             = aws_vpc.test_vpc.id
}

#AWS Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "transit_gateway_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.custom_asn_tgw.id
}

# AWS Transit Gateway Route Table Propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "route_table_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment_to_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.transit_gateway_route_table.id
  depends_on = [aws_vpn_connection.vpn_connection, aws_vpn_connection.site2site_vpn_for_azure]
}

# Transit Gateway Route Table Association
#resource "aws_ec2_transit_gateway_route" "azure_vnet_cidr" {
#  count                          = 2
#  destination_cidr_block         = "172.25.0.0/16"  ### Azure VNet CIDR
#  transit_gateway_attachment_id  = aws_vpn_connection.site2site_vpn_for_azure[count.index].transit_gateway_attachment_id
#  transit_gateway_route_table_id = aws_ec2_transit_gateway.custom_asn_tgw.association_default_route_table_id
#  blackhole                      = false
#}

# Introduce a time delay of 4 minutes 30 Seconds.
resource "time_sleep" "wait_270_seconds" {
  depends_on = [azurerm_virtual_network_gateway_connection.connection1, azurerm_virtual_network_gateway_connection.connection2, azurerm_virtual_network_gateway_connection.vpn_connection1, azurerm_virtual_network_gateway_connection.vpn_connection2]
  create_duration = "270s"
}

# Entry in Route of the Route Table of VPC for TG-Attachments and VPC CIDRs
resource "aws_route" "gcp_subnet_primary_range" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = var.ip_range_subnet
  transit_gateway_id        = aws_ec2_transit_gateway.custom_asn_tgw.id

  depends_on = [time_sleep.wait_270_seconds]
}

# Entry in Route of the Route Table of VPC for TG-Attachments and VPC CIDRs
resource "aws_route" "gcp_subnet_secondary_range_pods" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = var.pods_ip_range
  transit_gateway_id        = aws_ec2_transit_gateway.custom_asn_tgw.id

  depends_on = [time_sleep.wait_270_seconds]
}

# Entry in Route of the Route Table of VPC for TG-Attachments and VPC CIDRs
resource "aws_route" "gcp_subnet_secondary_range_service" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = var.services_ip_range
  transit_gateway_id        = aws_ec2_transit_gateway.custom_asn_tgw.id

  depends_on = [time_sleep.wait_270_seconds]
}

# Entry in Route of the Route Table of VPC for TG-Attachments and VPC CIDRs
resource "aws_route" "gcp_subnet_ip_public_range_subnet" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = var.ip_public_range_subnet
  transit_gateway_id        = aws_ec2_transit_gateway.custom_asn_tgw.id

  depends_on = [time_sleep.wait_270_seconds]
}

# Entry in Route of the Route Table of VPC for TG-Attachments and VPC CIDRs
resource "aws_route" "azure_vnet_cidr" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "172.25.0.0/16"  ### Azure VNet CIDR
  transit_gateway_id        = aws_ec2_transit_gateway.custom_asn_tgw.id

  depends_on = [time_sleep.wait_270_seconds]
}

# AWS VPN Connection for GCP
resource "aws_vpn_connection" "vpn_connection" {
  count               = 2
  transit_gateway_id  = aws_ec2_transit_gateway.custom_asn_tgw.id
  customer_gateway_id = count.index == 0 ? aws_customer_gateway.aws_cg[0].id : aws_customer_gateway.aws_cg[1].id
  type                = "ipsec.1"
  static_routes_only  = false    ### Dynamic (Requires BGP)

  # Tunnel 1 Configuration - Generic + IKEv2
  tunnel1_ike_versions = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  # Tunnel 2 Configuration - Generic + IKEv2
  tunnel2_ike_versions = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "generic-ikev2-vpn-${count.index + 1}"
  }
}

# AWS VPN Connection for Azure
resource "aws_vpn_connection" "site2site_vpn_for_azure" {
  count               = 2
  transit_gateway_id  = aws_ec2_transit_gateway.custom_asn_tgw.id
  customer_gateway_id = count.index == 0 ? aws_customer_gateway.aws_cg_for_azure[0].id : aws_customer_gateway.aws_cg_for_azure[1].id
  type                = "ipsec.1"
  static_routes_only  = false    ### Dynamic (Requires BGP)

  # Tunnel 1 Configuration - Generic + IKEv2
#  tunnel1_ike_versions = ["ikev2"]
  tunnel1_preshared_key = count.index == 0 ? random_password.vpn_secret_azure_tunnel1Instance0.result : random_password.vpn_secret_azure_tunnel1Instance1.result
  tunnel2_preshared_key = count.index == 0 ? random_password.vpn_secret_azure_tunnel2Instance0.result : random_password.vpn_secret_azure_tunnel2Instance1.result
  tunnel1_inside_cidr   = count.index == 0 ? "169.254.21.0/30" : "169.254.21.4/30"
  tunnel2_inside_cidr   = count.index == 0 ? "169.254.22.0/30" : "169.254.22.4/30"
#  tunnel1_phase1_encryption_algorithms = ["AES256"]
#  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
#  tunnel1_phase1_dh_group_numbers      = [14]
#  tunnel1_phase2_encryption_algorithms = ["AES256"]
#  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
#  tunnel1_phase2_dh_group_numbers      = [14]

  # Tunnel 2 Configuration - Generic + IKEv2
#  tunnel2_ike_versions = ["ikev2"]
#  tunnel2_phase1_encryption_algorithms = ["AES256"]
#  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
#  tunnel2_phase1_dh_group_numbers      = [14]
#  tunnel2_phase2_encryption_algorithms = ["AES256"]
#  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
#  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "site2site-vpn-connection-for-azure-${count.index + 1}"
  }
}
