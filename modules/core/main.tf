locals {
  project = "splunk"
}

data "openstack_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

# use datasources if we have to reference existing networks
#data "openstack_networking_router_v2" "AppSvc_T_vpc01" {
#  router_id = "b1ae5055-780b-45ad-b77e-f45339cd3aac"
#}

# How to reference existing interfaces?? Theres no datasource and a
# resource will inappropriately try to manage the resource
# Importing will not work as it then tries to manage the resource which
# is dangerous (it should be readonly)
#resource "openstack_networking_router_interface_v2" "AppSvc_T_net_AZ1" {
#  router_id = data.openstack_networking_router_v2.AppSvc_T_vpc01.id
#  subnet_id = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ1.id
#}
#
#resource "openstack_networking_router_interface_v2" "AppSvc_T_net_AZ2" {
#  router_id = data.openstack_networking_router_v2.AppSvc_T_vpc01.id
#  subnet_id = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ2.id
#}

#data "openstack_networking_network_v2" "AppSvc_T_net_AZ1" {
#  network_id = "6060ca85-04de-4a66-a586-add3a47ec89f"
#}

#data "openstack_networking_network_v2" "AppSvc_T_net_AZ2" {
#  network_id = "dd6c4c98-82ac-46b8-a83b-b884c7536b41"
#}

#data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ1" {
#  subnet_id = "41ce2481-b595-46d0-ae69-ad6547a06b06"
#}

#data "openstack_networking_subnet_v2" "AppSvc_T_subnet_AZ2" {
#  subnet_id = "b97e7c7d-d7a6-4170-8064-ef1ab2846bea"
#}

# use resources to manage our nets
#resource "openstack_networking_router_v2" "core" {
#  name                = "${local.project}-${var.stage}-router"
#  admin_state_up      = "true"
#  external_network_id = data.openstack_networking_network_v2.extnet.id
#}
#
#resource "openstack_networking_router_interface_v2" "core1" {
#  router_id = openstack_networking_router_v2.core.id
#  subnet_id = openstack_networking_subnet_v2.core1.id
#}
#
#resource "openstack_networking_router_interface_v2" "core2" {
#  router_id = openstack_networking_router_v2.core.id
#  subnet_id = openstack_networking_subnet_v2.core2.id
#}
#
#resource "openstack_networking_network_v2" "core1" {
#  name                    = "${local.project}-${var.stage}-net1"
#  # Error: Error creating openstack_networking_network_v2: Bad request with: [POST https://vpc.eu-ch.o13bb.otc.t-systems.com/v2.0/networks], error message: {"NeutronError":{"message":"Attribute 'availability_zone_hints' not allowed in POST","type":"HTTPBadRequest","detail":""}}
#  #availability_zone_hints = ["AZ1"]
#  admin_state_up          = true
#}
#
#resource "openstack_networking_network_v2" "core2" {
#  name                    = "${local.project}-${var.stage}-net2"
#  #availability_zone_hints = ["AZ2"]
#  admin_state_up          = true
#}
#
#resource "openstack_networking_subnet_v2" "core1" {
#  name            = "${local.project}-${var.stage}-subnet1"
#  network_id      = openstack_networking_network_v2.core1.id
#  cidr            = var.subnet_cidr1
#  ip_version      = 4
#  dns_nameservers = var.dns_servers
#}
#
#resource "openstack_networking_subnet_v2" "core2" {
#  name            = "${local.project}-${var.stage}-subnet2"
#  network_id      = openstack_networking_network_v2.core2.id
#  cidr            = var.subnet_cidr2
#  ip_version      = 4
#  dns_nameservers = var.dns_servers
#}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "splunk-vpc"
}

data "opentelekomcloud_networking_network_v2" "net-az1" {
  name = "splunk-net-az1-1"
}

data "opentelekomcloud_networking_network_v2" "net-az2" {
  name = "splunk-net-az2-1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az1" {
  name = "splunk-subnet-az1-1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az2" {
  name = "splunk-subnet-az2-1"
}

#data "opentelekomcloud_vpc_subnet_ids_v1" "subnet_ids" {
#  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
#}

#resource "opentelekomcloud_networking_router_interface_v2" "router-interface-az1" {
#  router_id = data.opentelekomcloud_vpc_v1.vpc.id
#  subnet_id = data.opentelekomcloud_vpc_subnet_v1.subnet_az1.id
#}

resource "openstack_compute_secgroup_v2" "indexer-secgrp" {
  # TODO: Extend/fix ports
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

resource "openstack_compute_secgroup_v2" "searchhead-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-${var.stage}-searchhead-secgrp"
  description = "${local.project}-${var.stage}-searchhead-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # search gui
  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # api
  rule {
    from_port   = 8089
    to_port     = 8089
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

resource "openstack_compute_secgroup_v2" "parser-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-${var.stage}-parser-secgrp"
  description = "${local.project}-${var.stage}-parser-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # syslog udp
  rule {
    from_port   = 514
    to_port     = 514
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  # syslog tcp/tls
  rule {
    from_port   = 6514
    to_port     = 6514
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

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${local.project}-${var.stage}-key"
  public_key = file("${path.module}/tsch-appl_rsa.pub")
}

