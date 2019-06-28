locals {
  project = "splunk"
}

data "openstack_networking_router_v2" "AppSvc_T_vpc01" {
  router_id = "b1ae5055-780b-45ad-b77e-f45339cd3aac"
}

data "openstack_networking_network_v2" "AppSvc_T_net_AZ1" {
  network_id = "6060ca85-04de-4a66-a586-add3a47ec89f"
}
data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ1" {
  subnet_id = "41ce2481-b595-46d0-ae69-ad6547a06b06"
}

data "openstack_networking_network_v2" "AppSvc_T_net_AZ2" {
  network_id = "dd6c4c98-82ac-46b8-a83b-b884c7536b41"
}
data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ2" {
  subnet_id = "b97e7c7d-d7a6-4170-8064-ef1ab2846bea"
}

resource "openstack_networking_network_v2" "core" {
  name           = "${local.project}-${var.stage}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "core" {
  name            = "${local.project}-${var.stage}-subnet"
  network_id      = "${openstack_networking_network_v2.core.id}"
  cidr            = "${var.subnet_cidr}"
  ip_version      = 4
  dns_nameservers = "${var.dns_servers}"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${local.project}-${var.stage}-key"
  public_key = file("${path.module}/tsch-appl_rsa.pub")
}
