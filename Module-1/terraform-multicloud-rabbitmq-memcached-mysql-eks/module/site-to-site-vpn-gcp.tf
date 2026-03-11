# HA VPN Gateway (GCP)
resource "google_compute_ha_vpn_gateway" "gcp_vpn_gateway" {
  name    = "${var.prefix}-ha-vpn-gateway"
  network = google_compute_network.gke_vpc.id
  region  = var.gcp_region
  stack_type = "IPV4_ONLY"
  gateway_ip_version = "IPV4"
}

resource "google_compute_router" "gcp_router" {
  name    = "${var.prefix}-cloud-router"
  network = google_compute_network.gke_vpc.name
  region  = var.gcp_region

  bgp {
    asn            = var.gcp_asn # 65000
    advertise_mode = "CUSTOM"    ###"DEFAULT"
    advertised_groups = ["ALL_SUBNETS"]
#    advertised_ip_ranges {
#      range = "${google_compute_global_address.private_ip_address.address}/${google_compute_global_address.private_ip_address.prefix_length}"
#    }
    advertised_ip_ranges {
      range = "35.199.192.0/19"  ###Dedicated source range used by Google Cloud DNS for outbound traffic when forwarding queries to external DNS Servers.
    }
  }
}

# External VPN Gateway (AWS)
resource "google_compute_external_vpn_gateway" "aws_tgw_gateway" {
  name            = "${var.prefix}-aws-vpn-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "Configuration with four IP addresses for HA"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_connection[0].tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_connection[0].tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.vpn_connection[1].tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.vpn_connection[1].tunnel2_address
  }
}

# VPN Connection (AWS <=> GCP)
resource "google_compute_vpn_tunnel" "gcp_vpn_tunnels" {
  count                           = 4
  name                            = "gcp-to-aws-tunnel-${count.index + 1}"
  shared_secret                   = count.index % 2 == 0 ? aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel2_preshared_key
  ike_version                     = 2
  router                          = google_compute_router.gcp_router.name
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.id
  vpn_gateway_interface           = count.index < 2 ? 0 :1  ###"${google_compute_ha_vpn_gateway.gcp_vpn_gateway[count.index].vpn_interfaces[count.index].id}"
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tgw_gateway.id
  peer_external_gateway_interface = count.index  ###"${google_compute_external_vpn_gateway.aws_tgw_gateway[count.index].interface[count.index].id}"
}

resource "google_compute_router_interface" "router_interfaces" {
  count      = 4
  name       = "if-bgp-session-${count.index + 1}"
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_vpn_tunnels[count.index].id
}

resource "google_compute_router_peer" "router_peers" {
  count           = 4
  name            = "bgp-session-${count.index + 1}"
  router          = google_compute_router.gcp_router.name
  interface       = google_compute_router_interface.router_interfaces[count.index].name
  peer_asn        = var.aws_asn
  ip_address      = count.index % 2 == 0 ? aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel1_cgw_inside_address : aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel2_cgw_inside_address
  peer_ip_address = count.index % 2 == 0 ? aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel1_vgw_inside_address : aws_vpn_connection.vpn_connection[floor(count.index / 2)].tunnel2_vgw_inside_address
}

###################################################### GCP to Azure Site-to-Site Connection ##############################################################

resource "google_compute_external_vpn_gateway" "azure_gateway" {
  name            = "gcp-azure-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "VPN gateway on Azure side"

  interface {
    id         = 0
    ip_address = azurerm_public_ip.vnetgtw1_ip.ip_address
  }

  interface {
    id         = 1
    ip_address = azurerm_public_ip.vnetgtw2_ip.ip_address
  }
}

# Generated preshared key used between GCP and Azure Site-to-Site Connection
resource "random_password" "vpn_secret_tunnel1" {
  length  = 32
  special = true
}

resource "random_password" "vpn_secret_tunnel2" {
  length  = 32
  special = true
}

# GCP HA VPN Tunnels
resource "google_compute_vpn_tunnel" "router_peers_azure" {
  count                           = 2
  name                            = "ha-azure-vpn-tunnel-${count.index + 1}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.id
  shared_secret                   = count.index == 0 ? random_password.vpn_secret_tunnel1.result : random_password.vpn_secret_tunnel2.result
  peer_external_gateway           = google_compute_external_vpn_gateway.azure_gateway.id
  peer_external_gateway_interface = count.index
  router                          = google_compute_router.gcp_router.name
  ike_version                     = 2
  vpn_gateway_interface           = count.index == 0 ? 0 :1
}

resource "google_compute_router_interface" "gcp_to_azure_router_interface" {
  count      = 2
  name       = "gcp-to-azure-router-interface-${count.index + 1}"
  router     = google_compute_router.gcp_router.name
  ip_range   = count.index == 0 ? "169.254.21.0/30" : "169.254.22.0/30"
  vpn_tunnel = google_compute_vpn_tunnel.router_peers_azure[count.index].name
}

resource "google_compute_router_peer" "gcp_to_azure_router_peer" {
  count                     = 2
  name                      = "gcp-to-azure-router-peer-${count.index + 1}"
  router                    = google_compute_router.gcp_router.name
  peer_ip_address           = count.index == 0 ? "169.254.21.2" : "169.254.22.2"
  peer_asn                  = var.azure_bgp_asn   ###"65515"
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp_to_azure_router_interface[count.index].name
}

##### Static Routing #####
#resource "google_compute_route" "azure_route" {
#  count       = 2
#  name        = "${var.prefix}-azure-route-${count.index + 1}"
#  network     = google_compute_network.gke_vpc.id
#  dest_range  = "172.25.0.0/16" # Azure VNet CIDR
#  priority    = 100
#  next_hop_vpn_tunnel = google_compute_vpn_tunnel.router_peers_azure[count.index].name
#}
