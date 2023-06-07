locals {
  rtr1_bgpcidr_if1 = "169.254.0.0/30"
  rtr1_bgpcidr_if2 = "169.254.1.0/30"
  
}

variable "gcp_region_1" {
  type    = string
  default = "europe-west2"
}

variable "gcp_project" {
  type        = string
  description = "Project to use for this config"
}

# added for gcpvm.tf
variable "project" {
  type        = string
  description = "Project to use for this config"
}


variable "network1_name" {
  description = "Provide Private Service Connection Global VPC name, note this VPC will have subnets from multiple regions, mapping to Global Cloud Service regions, such as Cloud SQL instance regions"
  type        = string
  default     = "gcp-native40"
}


variable "network2_name" {
  description = "Provide Private Service Connection Global VPC name, note this VPC will have subnets from multiple regions, mapping to Global Cloud Service regions, such as Cloud SQL instance regions"
  type        = string
  default     = "gcp-native30"
}

variable "region" {
  type        = string
  description = "Project to use for this config"
  default = "europe-west2"
}

variable "region2" {
  type        = string
  description = "Project to use for this config"
  default = "europe-west4"
}

variable "subnet1_cidr_range" {
  type        = string
  description = ""
  default = "10.40.40.0/24"
}


variable "subnet2_cidr_range" {
  type        = string
  description = ""
  default = "10.41.41.0/24"
}

variable "net2_subnet1_cidr_range" {
  type        = string
  description = ""
  default = "10.30.30.0/24"
}


variable "net2_subnet2_cidr_range" {
  type        = string
  description = ""
  default = "10.31.31.0/24"
}
variable "net1_cr_asn" {
  type        = string
  description = ""
  default = "65040"
}

variable "net2_cr_asn" {
  type        = string
  description = ""
  default = "65030"
}

variable "advertised_net1_ip1" {
  type        = string
  description = ""
  default = "10.240.240.0/24"
}

variable "advertised_net1_ip2" {
  type        = string
  description = ""
  default = "10.241.241.0/24"
}

variable "advertised_net2_ip1" {
  type        = string
  description = ""
  default = "10.40.40.0/24"
}

variable "advertised_net2_ip2" {
  type        = string
  description = ""
  default = "10.25.25.0/24"
}

variable "advertised_net2_ip3" {
  type        = string
  description = ""
  default = "10.5.5.0/24"
}

variable "account" {
  description = "Provide Aviatrix GCP Access Account name"
  type        = string
}

# Aviatrix provider
variable "avtx_controllerip" {
  type = string
}

variable "avtx_admin_user" {
  type = string
} 

variable "avtx_admin_password" {
  type = string
}



# Cloud VPN

variable "shared_secret" {
  description = "Cloud vpn to avtx transit"
  type        = string
  default     = "Aviatrix123#"
}



#  MTT transit
variable "mtt1_cidr_range" {
  type        = string
  description = ""
  default = "10.20.0.0/24"
}


variable "mtt1_asn" {
  type        = string
  description = ""
  default = "65520"
}

# spoke
variable "mtt1_spoke" {
  type        = string
  description = ""
  default = "10.25.25.0/24"
}