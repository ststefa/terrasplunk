locals {
  project = "splunk"
}

data "openstack_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

# use datasources if we have to reference existing networks
data "openstack_networking_router_v2" "AppSvc_T_vpc01" {
  router_id = "b1ae5055-780b-45ad-b77e-f45339cd3aac"
}

# How to reference existing interfaces?? Theres no datasource
#resource "openstack_networking_router_interface_v2" "AppSvc_T_net_AZ1" {
#  router_id = data.openstack_networking_router_v2.AppSvc_T_vpc01.id
#  subnet_id = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ1.id
#}
#
#resource "openstack_networking_router_interface_v2" "AppSvc_T_net_AZ2" {
#  router_id = data.openstack_networking_router_v2.AppSvc_T_vpc01.id
#  subnet_id = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ2.id
#}

data "openstack_networking_network_v2" "AppSvc_T_net_AZ1" {
  network_id = "6060ca85-04de-4a66-a586-add3a47ec89f"
}

data "openstack_networking_network_v2" "AppSvc_T_net_AZ2" {
  network_id = "dd6c4c98-82ac-46b8-a83b-b884c7536b41"
}

data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ1" {
  subnet_id = "41ce2481-b595-46d0-ae69-ad6547a06b06"
}

data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ2" {
  subnet_id = "b97e7c7d-d7a6-4170-8064-ef1ab2846bea"
}

# use resources to properly manage our nets
resource "openstack_networking_router_v2" "core" {
  name                = "${local.project}-${var.stage}-router"
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.extnet.id
}

resource "openstack_networking_router_interface_v2" "core1" {
  router_id = openstack_networking_router_v2.core.id
  subnet_id = openstack_networking_subnet_v2.core1.id
}

resource "openstack_networking_router_interface_v2" "core2" {
  router_id = openstack_networking_router_v2.core.id
  subnet_id = openstack_networking_subnet_v2.core2.id
}

resource "openstack_networking_network_v2" "core1" {
  name                    = "${local.project}-${var.stage}-network"
  #availability_zone_hints = ["AZ1"]
  admin_state_up          = true
}

resource "openstack_networking_network_v2" "core2" {
  name                    = "${local.project}-${var.stage}-network"
  #availability_zone_hints = ["AZ2"]
  admin_state_up          = true
}

resource "openstack_networking_subnet_v2" "core1" {
  name            = "${local.project}-${var.stage}-subnet1"
  network_id      = openstack_networking_network_v2.core1.id
  cidr            = var.subnet_cidr1
  ip_version      = 4
  dns_nameservers = var.dns_servers
}

resource "openstack_networking_subnet_v2" "core2" {
  name            = "${local.project}-${var.stage}-subnet2"
  network_id      = openstack_networking_network_v2.core2.id
  cidr            = var.subnet_cidr2
  ip_version      = 4
  dns_nameservers = var.dns_servers
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${local.project}-${var.stage}-key"
  public_key = file("${path.module}/tsch-appl_rsa.pub")
}

resource "openstack_compute_secgroup_v2" "indexer-secgrp" {
  name        = "${local.project}-${var.stage}-indexer-secgrp"
  description = "${local.project}-${var.stage}-indexer-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # indexr port
  rule {
    from_port   = 9997
    to_port     = 9997
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}
