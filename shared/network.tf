data "opentelekomcloud_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "${local.project}-vpc"
}

# disable data in favour of resources to really manage network
#data "opentelekomcloud_networking_network_v2" "netA-az1" {
#  name = "${local.project}-netA-az1"
#}
#
#data "opentelekomcloud_networking_network_v2" "netA-az2" {
#  name = "${local.project}-netA-az2"
#}
#
##data "opentelekomcloud_networking_network_v2" "netB-az1" {
##  name = "${local.project}-netB-az1"
##}
##
##data "opentelekomcloud_networking_network_v2" "netB-az2" {
##  name = "${local.project}-netB-az2"
##}
#
#data "opentelekomcloud_networking_network_v2" "netC-az1" {
#  name = "${local.project}-netC-az1"
#}
#
#data "opentelekomcloud_networking_network_v2" "netC-az2" {
#  name = "${local.project}-netC-az2"
#}
#
#data "opentelekomcloud_vpc_subnet_v1" "subnetA_az1" {
#  name = "${local.project}-subnetA-az1"
#}
#
#data "opentelekomcloud_vpc_subnet_v1" "subnetA_az2" {
#  name = "${local.project}-subnetA-az2"
#}
#
##data "opentelekomcloud_vpc_subnet_v1" "subnetB_az1" {
##  name = "${local.project}-subnetB-az1"
##}
##
##data "opentelekomcloud_vpc_subnet_v1" "subnetB_az2" {
##  name = "${local.project}-subnetB-az2"
##}
#
#data "opentelekomcloud_vpc_subnet_v1" "subnetC_az1" {
#  name = "${local.project}-subnetC-az1"
#}
#
#data "opentelekomcloud_vpc_subnet_v1" "subnetC_az2" {
#  name = "${local.project}-subnetC-az2"
#}

#data "opentelekomcloud_vpc_subnet_ids_v1" "subnet_ids" {
#  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
#}

resource "opentelekomcloud_vpc_subnet_v1" "subnetA-az1" {
  name              = "${local.project}-subnetA-az1"
  cidr              = module.variables.subnet_cidr["netA-az1"]
  gateway_ip        = module.variables.gateway["netA-az1"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-01"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netA-az1" {
  matching_subnet_cidr = module.variables.subnet_cidr["netA-az1"]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnetA-az2" {
  name              = "${local.project}-subnetA-az2"
  cidr              = module.variables.subnet_cidr["netA-az2"]
  gateway_ip        = module.variables.gateway["netA-az2"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-02"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netA-az2" {
  matching_subnet_cidr = module.variables.subnet_cidr["netA-az2"]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnetB-az1" {
  # cannot currently have spare net on test tenant because no room left
  count             = local.tenant_name == "tsch_rz_p_001" ? 1 : 0
  name              = "${local.project}-subnetB-az1"
  cidr              = module.variables.subnet_cidr["netB-az1"]
  gateway_ip        = module.variables.gateway["netB-az1"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-01"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netB-az1" {
  count                = local.tenant_name == "tsch_rz_p_001" ? 1 : 0
  matching_subnet_cidr = module.variables.subnet_cidr["netB-az1"]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnetB-az2" {
  count             = local.tenant_name == "tsch_rz_p_001" ? 1 : 0
  name              = "${local.project}-subnetB-az2"
  cidr              = module.variables.subnet_cidr["netB-az2"]
  gateway_ip        = module.variables.gateway["netB-az2"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-02"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netB-az2" {
  count                = local.tenant_name == "tsch_rz_p_001" ? 1 : 0
  matching_subnet_cidr = module.variables.subnet_cidr["netB-az2"]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnetC-az1" {
  name              = "${local.project}-subnetC-az1"
  cidr              = module.variables.subnet_cidr["netC-az1"]
  gateway_ip        = module.variables.gateway["netC-az1"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-01"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netC-az1" {
  matching_subnet_cidr = module.variables.subnet_cidr["netC-az1"]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnetC-az2" {
  name              = "${local.project}-subnetC-az2"
  cidr              = module.variables.subnet_cidr["netC-az2"]
  gateway_ip        = module.variables.gateway["netC-az2"]
  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-02"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}
data "opentelekomcloud_networking_network_v2" "netC-az2" {
  matching_subnet_cidr = module.variables.subnet_cidr["netC-az2"]
}

#resource "opentelekomcloud_networking_router_interface_v2" "router-interface-az1" {
#  router_id = data.opentelekomcloud_vpc_v1.vpc.id
#  subnet_id = data.opentelekomcloud_vpc_subnet_v1.subnet_az1.id
#}
