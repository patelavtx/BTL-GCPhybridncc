
### NATIVE VPC + Cloud Router + HAVPN ###
# https://cloud.google.com/network-connectivity/docs/vpn/how-to/automate-vpn-setup-with-terraform

# 1
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network

# native vpc network 1 and 2
resource "google_compute_network" "network1" {
  project                 = var.gcp_project
  name                    = var.network1_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_network" "network2" {
  project                 = var.gcp_project
  name                    = var.network2_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork

# Create subnets for net1 and net2 map to a region.

# net1 subnets
resource "google_compute_subnetwork" "network1_subnet1" {
  name          = "${var.network1_name}-subnet1"
  ip_cidr_range = var.subnet1_cidr_range
  region        = var.gcp_region_1
  network       = google_compute_network.network1.id
}

resource "google_compute_subnetwork" "network1_subnet2" {
  name          = "${var.network1_name}-subnet2"
  ip_cidr_range = var.subnet2_cidr_range
  region        = var.region2
  network       = google_compute_network.network1.id
}


# net2 subnets
resource "google_compute_subnetwork" "network2_subnet1" {
  name          = "${var.network2_name}-subnet1"
  ip_cidr_range = var.net2_subnet1_cidr_range
  region        = var.gcp_region_1
  network       = google_compute_network.network2.id
}

resource "google_compute_subnetwork" "network2_subnet2" {
  name          = "${var.network2_name}-subnet2"
  ip_cidr_range = var.net2_subnet2_cidr_range
  region        = var.region2
  network       = google_compute_network.network2.id
}


# 2
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
# Create cloud routers per network 

# Net1 CR
resource "google_compute_router" "network1_cloud_router" {
  project  = var.gcp_project
  region   = var.gcp_region_1
  name     = "${var.network1_name}-${var.gcp_region_1}-cr"
  network  = google_compute_network.network1.name
  bgp {
    asn               = var.net1_cr_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    advertised_ip_ranges {
      range = var.advertised_net1_ip1
    }
    advertised_ip_ranges {
      range = var.advertised_net1_ip2
    }
  }
}


# Net2 CR
resource "google_compute_router" "network2_cloud_router" {
  project  = var.gcp_project
  region   = var.gcp_region_1
  name     = "${var.network2_name}-${var.gcp_region_1}-cr"
  network  = google_compute_network.network2.name
  bgp {
    asn               = var.net2_cr_asn
    #advertise_mode    = "CUSTOM"
    advertise_mode    = "DEFAULT"
    #advertised_groups = ["ALL_SUBNETS"]

    #advertised_ip_ranges {
    #  range = var.advertised_net2_ip1
    #}
    #advertised_ip_ranges {
    #  range = var.advertised_net2_ip2
    #}
    #advertised_ip_ranges {
    #  range = var.advertised_net2_ip3
    #}
  }
}


# 3 
# https://registry.terraform.io/providers/DrFaust92/google/latest/docs/resources/compute_ha_vpn_gateway
# Cloud VPN

# net1 havpn
resource "google_compute_ha_vpn_gateway" "network1_ha_gateway1" {
  region  = var.gcp_region_1
  name    = "${var.network1_name}-${var.gcp_region_1}-havpngw"
  network = google_compute_network.network1.id
}

# net2 havpn
resource "google_compute_ha_vpn_gateway" "network2_ha_gateway1" {
  region  = var.gcp_region_1
  name    = "${var.network2_name}-${var.gcp_region_1}-havpngw"
  network = google_compute_network.network2.id
}


# 4
# https://registry.terraform.io/providers/DrFaust92/google/latest/docs/resources/compute_vpn_tunnel
# Cloud VPN tunnels from native vpc (network1 to avtxnetwork)

# Net1 havpn tunnels
resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "${var.network1_name}-${var.gcp_region_1}-havpngw-tun1"
  region                          = var.gcp_region_1
  vpn_gateway                     = google_compute_ha_vpn_gateway.network1_ha_gateway1.id
  peer_gcp_gateway                = google_compute_ha_vpn_gateway.network2_ha_gateway1.id
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.network1_cloud_router.id
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name                            = "${var.network1_name}-${var.gcp_region_1}-havpngw-tun2"
  region                          = var.gcp_region_1
  vpn_gateway                     = google_compute_ha_vpn_gateway.network1_ha_gateway1.id
  peer_gcp_gateway                = google_compute_ha_vpn_gateway.network2_ha_gateway1.id
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.network1_cloud_router.id
  vpn_gateway_interface           = 1
}


# Net2 havpn tunnels
resource "google_compute_vpn_tunnel" "tunnel3" {
  name                            = "${var.network2_name}-${var.gcp_region_1}-havpngw-tun1"
  region                          = var.gcp_region_1
  vpn_gateway                     = google_compute_ha_vpn_gateway.network2_ha_gateway1.id
  peer_gcp_gateway                = google_compute_ha_vpn_gateway.network1_ha_gateway1.id
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.network2_cloud_router.id
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  name                            = "${var.network2_name}-${var.gcp_region_1}-havpngw-tun2"
  region                          = var.gcp_region_1
  vpn_gateway                     = google_compute_ha_vpn_gateway.network2_ha_gateway1.id
  peer_gcp_gateway                = google_compute_ha_vpn_gateway.network1_ha_gateway1.id
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.network2_cloud_router.id
  vpn_gateway_interface           = 1
}



# 5
# https://registry.terraform.io/providers/DrFaust92/google/latest/docs/resources/compute_router_interface
# https://registry.terraform.io/providers/DrFaust92/google/latest/docs/resources/compute_router_peer
# Cloud router interface (bgp session)

# Net1
resource "google_compute_router_interface" "router1_interface1" {
  name       = "${var.network1_name}-${var.gcp_region_1}-cr-if1"
  router     = google_compute_router.network1_cloud_router.name
  region     = var.gcp_region_1
  ip_range   = join("/", [cidrhost(local.rtr1_bgpcidr_if1,1),"30"])  # bgp p2p subnet
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "${var.network1_name}-${var.gcp_region_1}-cr-peer1"
  router                    = google_compute_router.network1_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = cidrhost(local.rtr1_bgpcidr_if1,2)
  peer_asn                  = var.net2_cr_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "${var.network1_name}-${var.gcp_region_1}-cr-if2"
  router     = google_compute_router.network1_cloud_router.name
  region     = var.gcp_region_1
  ip_range   = join("/", [cidrhost(local.rtr1_bgpcidr_if2,2),"30"])
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "${var.network1_name}-${var.gcp_region_1}-cr-peer2"
  router                    = google_compute_router.network1_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = cidrhost(local.rtr1_bgpcidr_if2,1)
  peer_asn                  = var.net2_cr_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}


# Net2
resource "google_compute_router_interface" "router2_interface1" {
  name       = "${var.network2_name}-${var.gcp_region_1}-cr-if1"
  router     = google_compute_router.network2_cloud_router.name
  region     = var.gcp_region_1
  ip_range   = join("/", [cidrhost(local.rtr1_bgpcidr_if1,2),"30"]) 
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "router2_peer1" {
  name                      = "${var.network2_name}-${var.gcp_region_1}-cr-peer1"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = cidrhost(local.rtr1_bgpcidr_if1,1)
  peer_asn                  = var.net1_cr_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface1.name
}

resource "google_compute_router_interface" "router2_interface2" {
  name       = "${var.network2_name}-${var.gcp_region_1}-cr-if2"
  router     = google_compute_router.network2_cloud_router.name
  region     = var.gcp_region_1
  ip_range   = join("/", [cidrhost(local.rtr1_bgpcidr_if2,1),"30"])
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4.name
}

resource "google_compute_router_peer" "router2_peer2" {
  name                      = "${var.network2_name}-${var.gcp_region_1}-cr-peer2"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = cidrhost(local.rtr1_bgpcidr_if2,2)
  peer_asn                  = var.net1_cr_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface2.name
}


