
### Create Avtx MTT gateway + Cloud Router interface and Peer  ###

# **** use gcp-ncc module https://registry.terraform.io/modules/terraform-aviatrix-modules/gcp-ncc/aviatrix/latest ****

# 1
#https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-transit/aviatrix/latest

# Build Aviatrix Transit with Multi-tier-transit enabled
module "mc-transit" {
  source                 = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version                = "2.5.0" # Lookup module version to controller version mapping: https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-transit/aviatrix/latest
  cloud                  = "GCP"
  region                 = var.gcp_region_1
  cidr                   = var.mtt1_cidr_range
  account                = var.account
  enable_multi_tier_transit = true
  learned_cidr_approval = true                # added as net2 cr will be advertising routes to allow net1 to avtx env reachability; control what is accepted
  enable_bgp_over_lan    = true
  enable_transit_firenet = false
  name                   = "${var.network2_name}-mtt1-transit20"
  gw_name                = "${var.network2_name}-mtt1-transit20"
  bgp_lan_interfaces = [{
    vpc_id = google_compute_network.network2.name
    subnet = google_compute_subnetwork.network2_subnet1.ip_cidr_range       # cidr
}]

  ha_bgp_lan_interfaces = [{
    vpc_id = google_compute_network.network2.name
    subnet = google_compute_subnetwork.network2_subnet1.ip_cidr_range       # cidr
}]
  local_as_number = var.mtt1_asn
}



# 2
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_hub

#  Create NCC - used to allow avtx transit gw to exchange BGP
resource "google_network_connectivity_hub" "gcc_ncc_hub" {
  project  = var.gcp_project
  name     = "${var.network2_name}-NCC"
}



# 2a
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_spoke
#  NCC spoke ans hub association ;    URI - gcloud compute instances list --uri

## INFO - How to get URI,  other than GUI?
/*
 gcloud compute instances list --uri | grep -i mtt1
https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-b/instances/gcp-native30-mtt1-transit20
https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-c/instances/gcp-native30-mtt1-transit20-hagw
*/


# NCC 'spoke' conn to avtx transit gateway AND net1 HAvpn tunnel to allow BGP routes exchange
resource "google_network_connectivity_spoke" "gcp_ncc_spoke" {
  project  = var.gcp_project
  name     = "${var.network2_name}-nccspoke"
  location = var.gcp_region_1
  hub      = google_network_connectivity_hub.gcc_ncc_hub.id
  linked_router_appliance_instances {
    instances {
      #virtual_machine = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-b/instances/gcp-native30-mtt1-transit20"       #URI
      virtual_machine = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.vpc_reg}/instances/${module.mc-transit.transit_gateway.gw_name}"
      ip_address      = module.mc-transit.transit_gateway.bgp_lan_ip_list[0]
    }
    instances {
      #virtual_machine = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-c/instances/gcp-native30-mtt1-transit20-hagw"   #URI
      virtual_machine = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.ha_zone}/instances/${module.mc-transit.transit_gateway.ha_gw_name}"
      ip_address      = module.mc-transit.transit_gateway.ha_bgp_lan_ip_list[0]
    }
      site_to_site_data_transfer = true
  }
  depends_on = [ module.mc-transit ]
}


resource "google_network_connectivity_spoke" "gcp_ncc_cr_spoke" {
  project  = var.gcp_project
  name     = "${var.network2_name}-nccspoke-cr"
  location = var.gcp_region_1
  hub      = google_network_connectivity_hub.gcc_ncc_hub.id
  
  linked_vpn_tunnels {
      uris = [google_compute_vpn_tunnel.tunnel3.id, google_compute_vpn_tunnel.tunnel4.id]
      site_to_site_data_transfer = true
  }
}



# 3   *** network2 cR***
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address

#Provision Cloud Router with static ips for  interface and BGP session  for AVTX
resource "google_compute_address" "cr_primary_addr" {
  project      = var.project
  name         = "${var.network2_name}-cr-primary-addr"
  region       = google_compute_subnetwork.network2_subnet1.region
  subnetwork   = google_compute_subnetwork.network2_subnet1.id 
  address_type = "INTERNAL"
  address      = cidrhost(var.net2_subnet1_cidr_range, (pow(2, (32 - tonumber(split("/", var.net2_subnet1_cidr_range)[1]))) - 4))
}

#Provision Cloud Router redundant interface address
resource "google_compute_address" "cr_redundant_addr" {
  project      = var.project
  name         = "${var.network2_name}-cr-redundant-addr"
  region       = google_compute_subnetwork.network2_subnet1.region
  subnetwork   = google_compute_subnetwork.network2_subnet1.id 
  address_type = "INTERNAL"
  address      = cidrhost(var.net2_subnet1_cidr_range, (pow(2, (32 - tonumber(split("/", var.net2_subnet1_cidr_range)[1]))) - 3))
}


# 3a 
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface

# Create Cloud Router redundant interface first
resource "google_compute_router_interface" "cr_redundant_interface" {
  project            = var.project
  name               = "${var.network2_name}-int-redundant"
  region             = google_compute_router.network2_cloud_router.region
  router             = google_compute_router.network2_cloud_router.name
  subnetwork         = google_compute_subnetwork.network2_subnet1.self_link
  private_ip_address = google_compute_address.cr_redundant_addr.address
}

# Create Cloud Router primary interface, note it references the redundant interface
resource "google_compute_router_interface" "cr_primary_interface" {
  project             = var.project
  name                = "${var.network2_name}-int-primary"
 region             = google_compute_router.network2_cloud_router.region
  router             = google_compute_router.network2_cloud_router.name
  subnetwork         = google_compute_subnetwork.network2_subnet1.self_link
  private_ip_address = google_compute_address.cr_primary_addr.address
  redundant_interface = google_compute_router_interface.cr_redundant_interface.name
}


# 4
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer

# Configure four Cloud Router BGP peers between with Cloud Router primary/redundant interfaces with Aviatrix Primary/HA Transit Gateways in NCC
resource "google_compute_router_peer" "cr_primary_int_peer_with_primary_gw" {
  project                   = var.project
  name                      = "${var.network2_name}-cr-pri-int-peer"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = module.mc-transit.transit_gateway.bgp_lan_ip_list[0]
  peer_asn                  = module.mc-transit.transit_gateway.local_as_number
  interface                 = google_compute_router_interface.cr_primary_interface.name
  #router_appliance_instance = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-b/instances/gcp-native30-mtt1-transit20"
  router_appliance_instance = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.vpc_reg}/instances/${module.mc-transit.transit_gateway.gw_name}"
  depends_on = [
    google_network_connectivity_spoke.gcp_ncc_spoke
  ]
}

resource "google_compute_router_peer" "cr_primary_int_peer_with_ha_gw" {
  project                   = var.project
  name                      = "${var.network2_name}-cr-pri-int-hapeer"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = module.mc-transit.transit_gateway.ha_bgp_lan_ip_list[0]
  peer_asn                  = module.mc-transit.transit_gateway.local_as_number
  interface                 = google_compute_router_interface.cr_primary_interface.name
  #router_appliance_instance = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-c/instances/gcp-native30-mtt1-transit20-hagw"
  router_appliance_instance = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.ha_zone}/instances/${module.mc-transit.transit_gateway.ha_gw_name}"
  depends_on = [
    google_network_connectivity_spoke.gcp_ncc_spoke
  ]
}

resource "google_compute_router_peer" "cr_redundant_int_peer_with_primary_gw" {
  project                   = var.project
  name                      = "${var.network2_name}-cr-red-int-peer"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = module.mc-transit.transit_gateway.bgp_lan_ip_list[0]
  peer_asn                  = module.mc-transit.transit_gateway.local_as_number
  interface                 = google_compute_router_interface.cr_redundant_interface.name
  # ? https://www.googleapis.com/compute/v1
  #router_appliance_instance = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-b/instances/gcp-native30-mtt1-transit20"
  router_appliance_instance = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.vpc_reg}/instances/${module.mc-transit.transit_gateway.gw_name}"
  depends_on = [
    google_network_connectivity_spoke.gcp_ncc_spoke
  ]
}

resource "google_compute_router_peer" "cr_redundant_int_peer_with_ha_gw" {
  project                   = var.project
  name                      = "${var.network2_name}-cr-red-int-hapeer"
  router                    = google_compute_router.network2_cloud_router.name
  region                    = var.gcp_region_1
  peer_ip_address           = module.mc-transit.transit_gateway.ha_bgp_lan_ip_list[0]
  peer_asn                  = module.mc-transit.transit_gateway.local_as_number
  interface                 = google_compute_router_interface.cr_redundant_interface.name
  #router_appliance_instance = "https://www.googleapis.com/compute/v1/projects/apatel-01/zones/europe-west2-c/instances/gcp-native30-mtt1-transit20-hagw"
  router_appliance_instance = "/projects/${var.gcp_project}/zones/${module.mc-transit.transit_gateway.ha_zone}/instances/${module.mc-transit.transit_gateway.ha_gw_name}"
  depends_on = [
    google_network_connectivity_spoke.gcp_ncc_spoke
  ]
}




# 5
# https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_transit_external_device_conn

# Create an Aviatrix Transit External Device Connection to establish BGP over LAN towards Cloud Router
resource "aviatrix_transit_external_device_conn" "bgp_over_lan" {
  vpc_id                    = module.mc-transit.transit_gateway.vpc_id
  connection_name           = google_compute_router.network2_cloud_router.name
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  ha_enabled                = true
  enable_bgp_lan_activemesh = true

  gw_name = module.mc-transit.transit_gateway.gw_name


  bgp_local_as_num  = module.mc-transit.transit_gateway.local_as_number
  bgp_remote_as_num = var.net2_cr_asn
  remote_lan_ip     = google_compute_router_interface.cr_primary_interface.private_ip_address
  local_lan_ip      = module.mc-transit.transit_gateway.bgp_lan_ip_list[0]

  backup_bgp_remote_as_num = var.net2_cr_asn
  backup_remote_lan_ip     = google_compute_router_interface.cr_redundant_interface.private_ip_address
  backup_local_lan_ip      = module.mc-transit.transit_gateway.ha_bgp_lan_ip_list[0]
}





# 6
#  Create Avtx core transit to MTT transit peering

resource "aviatrix_transit_gateway_peering" "core-mtt1-peering" {
  transit_gateway_name1                       = module.mc-transit.transit_gateway.gw_name
  transit_gateway_name2                       = "gcp-euwest2-transit"
  
  enable_peering_over_private_network         = false
  enable_insane_mode_encryption_over_internet = false
depends_on = [ module.mc-transit ]
}
