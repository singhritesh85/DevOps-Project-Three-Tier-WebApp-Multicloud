################################################################################################################################## 
#Bidirectional DNS Resolver between AWS and Azure
##################################################################################################################################

############################################# Inbound Endpoint Security Group ####################################################

resource "aws_security_group" "inbound_sg" {
  name   = "${var.prefix}-inbound-endpoint-sg"
  vpc_id = aws_vpc.test_vpc.id
}

resource "aws_security_group_rule" "inbound_egress" {
  security_group_id = aws_security_group.inbound_sg.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]    ###["172.25.0.0/16"]
}

resource "aws_security_group_rule" "inbound_udp_ingress" {
  security_group_id = aws_security_group.inbound_sg.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]    ###["172.25.0.0/16"]
}

resource "aws_security_group_rule" "inbound_tcp_ingress" {
  security_group_id = aws_security_group.inbound_sg.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = ["172.25.0.0/16", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]
}

############################################### Outbound Endpoint Security Group ##################################################

resource "aws_security_group" "outbound_sg" {
  name   = "${var.prefix}-outbound-endpoint-sg"
  vpc_id = aws_vpc.test_vpc.id
}

resource "aws_security_group_rule" "outbound_udp_egress" {
  security_group_id = aws_security_group.outbound_sg.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]    ###["172.25.0.0/16"]
}

resource "aws_security_group_rule" "outbound_tcp_egress" {
  security_group_id = aws_security_group.outbound_sg.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]   ###["172.25.0.0/16"]
}

resource "aws_security_group_rule" "outbound_ingress" {
  security_group_id = aws_security_group.outbound_sg.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["172.25.0.0/16", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]     ###["172.25.0.0/16"]
}

######################################## Route 53 Inbound Endpoint #####################################################

resource "aws_route53_resolver_endpoint" "inbound_endpoint" {
  name      = "${var.prefix}-route53-inbound-endpoint"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.inbound_sg.id]

  dynamic "ip_address" {
    for_each = aws_subnet.private_subnet.*.id
    content {
      subnet_id = ip_address.value
    }
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

######################################### Route53 Outbound Endpoint #####################################################

resource "aws_route53_resolver_endpoint" "outbound_endpoint" {
  name      = "${var.prefix}-route53-outbound-endpoint"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.outbound_sg.id]

  dynamic "ip_address" {
    for_each = aws_subnet.private_subnet.*.id
    content {
      subnet_id = ip_address.value
    }
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "aws_route53_resolver_rule" "route53_resolver_rule" {
  domain_name          = "dexter-mysql3.private.mysql.database.azure.com."    ###"."     ###Catch-all: Matches all domain names
  name                 = "outbound"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound_endpoint.id

  target_ip {
    ip = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound.ip_configurations[0].private_ip_address
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "aws_route53_resolver_rule_association" "route53_resolver_rule_association" {
  resolver_rule_id = aws_route53_resolver_rule.route53_resolver_rule.id
  vpc_id           = aws_vpc.test_vpc.id

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

################################### Azure Private DNS Resolver Inbound Endpoint #########################################

resource "azurerm_private_dns_resolver" "private_dns_resolver" {
  name                = "${var.prefix}-azure-pdr-resolver"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  virtual_network_id  = azurerm_virtual_network.vnet-1.id

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "private_dns_resolver_inbound" {
  name                    = "${var.prefix}-azure-inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.private_dns_resolver.id
  location                = azurerm_resource_group.vnetconnection_rg.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id = azurerm_subnet.inbound_subnet.id
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "private_dns_resolver_outbound" {
  name                    = "${var.prefix}-azure-outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.private_dns_resolver.id
  location                = azurerm_private_dns_resolver.private_dns_resolver.location
  subnet_id               = azurerm_subnet.outbound_subnet.id

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "private_dns_resolver_forwarding_ruleset" {
  name                                       = "${var.prefix}-pdr-resolver-aws-ruleset"
  resource_group_name                        = azurerm_resource_group.vnetconnection_rg.name
  location                                   = azurerm_resource_group.vnetconnection_rg.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound.id]

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "private_dns_resolver_forwarding_rule" {
  name                      = "${var.prefix}-pdr-resolver-aws-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.private_dns_resolver_forwarding_ruleset.id
  domain_name               = "eks.amazonaws.com."        ###"."  ### For all domains
  enabled                   = true

  dynamic "target_dns_servers" {
    for_each = aws_route53_resolver_endpoint.inbound_endpoint.ip_address
    content {
      ip_address = target_dns_servers.value.ip
      port       = 53
    }
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

##########################################################################################################################################
# DNS Resolution of Azure MySQL Flexible Server Private DNS from GCP
##########################################################################################################################################

resource "google_dns_managed_zone" "azure_forwarding_zone" {
  name        = "${var.prefix}-azure-mysql-private-link-zone"
  dns_name    = "dexter-mysql3.private.mysql.database.azure.com."
  description = "Forwarding zone for Azure MySQL private link resolution"
  visibility  = "private"
  forwarding_config {
    target_name_servers {
      ipv4_address    = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound.ip_configurations[0].private_ip_address
      forwarding_path = "private"
    }
  }
  private_visibility_config {
    networks {
      network_url = google_compute_network.gke_vpc.id
    }
  }
}

resource "google_dns_policy" "gcp_dns_inbound_policy" {
  name                      = "${var.prefix}-inbound-dns-policy"
  enable_inbound_forwarding = true
  enable_logging            = false

  networks {
    network_url = google_compute_network.gke_vpc.id
  }
}

##########################################################################################################################################
# DNS Resolution of AWS EKS Endpoint from GCP 
##########################################################################################################################################

resource "google_dns_managed_zone" "aws_forwarding_zone" {
  name        = "${var.prefix}-aws-private-zone"
  dns_name    = "eks.amazonaws.com."
  description = "Forwarding to AWS DNS"
  visibility  = "private"
  forwarding_config {
    dynamic "target_name_servers" {
      for_each = aws_route53_resolver_endpoint.inbound_endpoint.ip_address
      content {
        ipv4_address = target_name_servers.value.ip
        forwarding_path = "private"
      }
    }
  }
  private_visibility_config {
    networks {
      network_url = google_compute_network.gke_vpc.id
    }
  }
}
