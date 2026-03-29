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
  cidr_blocks = ["0.0.0.0/0"]     ###["10.224.0.0/12"]
}

resource "aws_security_group_rule" "inbound_udp_ingress" {
  security_group_id = aws_security_group.inbound_sg.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = ["10.224.0.0/12", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]
}

resource "aws_security_group_rule" "inbound_tcp_ingress" {
  security_group_id = aws_security_group.inbound_sg.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = ["10.224.0.0/12", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]
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
  cidr_blocks = ["0.0.0.0/0"]        ###["10.224.0.0/12"]
}

resource "aws_security_group_rule" "outbound_tcp_egress" {
  security_group_id = aws_security_group.outbound_sg.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_ingress" {
  security_group_id = aws_security_group.outbound_sg.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["10.224.0.0/12", "10.10.0.0/20", "172.16.0.0/28", "172.17.0.0/16", "172.19.0.0/16", "10.20.0.0/20"]
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

resource "aws_route53_resolver_rule" "route53_resolver_rule_aks" {
  domain_name          = "privatelink.eastus.azmk8s.io."  ###"." ###Catch-all: Matches all domain names ###"dexter-mysql3.private.mysql.database.azure.com"
  name                 = "outbound"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound_endpoint.id

  target_ip {
    ip = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound.ip_configurations[0].private_ip_address
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]
}

resource "aws_route53_resolver_rule_association" "route53_resolver_rule_association_aks" {
  resolver_rule_id = aws_route53_resolver_rule.route53_resolver_rule_aks.id
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

resource "azurerm_private_dns_resolver_forwarding_rule" "private_dns_resolver_forwarding_rule_eks" {
  name                      = "${var.prefix}-pdr-resolver-aws-rule-eks"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.private_dns_resolver_forwarding_ruleset.id
  domain_name               = "eks.amazonaws.com." ###  "."  ### For all domains  ###"dexter-mysql3.private.mysql.database.azure.com."
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

resource "azurerm_private_dns_resolver_forwarding_rule" "private_dns_resolver_forwarding_rule_elb" {
  name                      = "${var.prefix}-pdr-resolver-aws-rule-elb"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.private_dns_resolver_forwarding_ruleset.id
  domain_name               = "elb.amazonaws.com." ###  "."  ### For all domains  ###"dexter-mysql3.private.mysql.database.azure.com."
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

resource "azurerm_private_dns_resolver_forwarding_rule" "private_dns_resolver_forwarding_rule_nlb" {
  name                      = "${var.prefix}-pdr-resolver-aws-rule-nlb"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.private_dns_resolver_forwarding_ruleset.id
  domain_name               = "elb.${data.aws_region.reg.id}.amazonaws.com." ###"."  ### For all domains  ###"dexter-mysql3.private.mysql.database.azure.com."
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
# DNS Resolution of Azure AKS Endpoint from GCP
##########################################################################################################################################

resource "google_dns_managed_zone" "azure_forwarding_zone" {
  name        = "${var.prefix}-azure-private-link-zone"
  dns_name    = "privatelink.eastus.azmk8s.io."    ###"dexter-mysql3.private.mysql.database.azure.com."
  description = "Forwarding to Azure DNS"
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

resource "google_dns_policy" "gcp_dns_inbound_policy_azure" {
  name                      = "${var.prefix}-inbound-dns-policy-aws-azure"
  enable_inbound_forwarding = true
  enable_logging            = false

  networks {
    network_url = google_compute_network.gke_vpc.id
  }
}

#resource "google_dns_policy" "gcp_dns_outbound_policy_azure" {
#  name                      = "${var.prefix}-outbound-dns-policy-azure"
#  enable_inbound_forwarding = false
#  enable_logging            = true

#  networks {
#    network_url = google_compute_network.gke_vpc.id
#  }

#  alternative_name_server_config {
#    target_name_servers {
#      ipv4_address = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound.ip_configurations[0].private_ip_address
#    }
#  }
#}

##########################################################################################################################################
# DNS Resolution of AWS EKS Endpoint, ELB and NLB from GCP
##########################################################################################################################################

resource "google_dns_managed_zone" "aws_eks_forwarding_zone" {
  name        = "${var.prefix}-aws-eks-private-zone"
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

#resource "google_dns_policy" "gcp_dns_inbound_policy_aws" {
#  name                      = "${var.prefix}-inbound-dns-policy-aws"
#  enable_inbound_forwarding = true
#  enable_logging            = false

#  networks {
#    network_url = google_compute_network.gke_vpc.id
#  }
#}

#resource "google_dns_policy" "gcp_dns_outbound_policy_aws" {
#  name                      = "${var.prefix}-outbound-dns-policy-aws"
#  enable_inbound_forwarding = false
#  enable_logging            = true

#  networks {
#    network_url = google_compute_network.gke_vpc.id
#  }

#  alternative_name_server_config {
#    dynamic "target_name_servers" {
#      for_each = aws_route53_resolver_endpoint.inbound_endpoint.ip_address
#      content {
#        ipv4_address = target_name_servers.value.ip
#      }
#    }
#  }
#}

resource "google_dns_managed_zone" "aws_elb_forwarding_zone" {
  name        = "${var.prefix}-aws-elb-private-zone"
  dns_name    = "elb.amazonaws.com."
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

resource "google_dns_managed_zone" "aws_nlb_forwarding_zone" {
  name        = "${var.prefix}-aws-nlb-private-zone"
  dns_name    = "elb.${data.aws_region.reg.id}.amazonaws.com."
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

