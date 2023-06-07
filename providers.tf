provider "google" {
  region  = var.gcp_region_1
  project = var.gcp_project
}


provider "aviatrix" {
  controller_ip           = var.avtx_controllerip
  username                = var.avtx_admin_user
  password                = var.avtx_admin_password
  skip_version_validation = false
}