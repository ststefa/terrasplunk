locals {
  project = "splunk"
}


module "variables" {
  source    = "../modules/variables"
  workspace = terraform.workspace
  stage     = "dontcare"
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  #delegated_project = "eu-ch_splunk"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

terraform {
  required_version = ">= 0.12"
}

data "opentelekomcloud_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "${local.project}-vpc"
}

data "opentelekomcloud_networking_network_v2" "neta-az1" {
  name = "${local.project}-neta-az1"
}

data "opentelekomcloud_networking_network_v2" "neta-az2" {
  name = "${local.project}-neta-az2"
}

data "opentelekomcloud_networking_network_v2" "netb-az1" {
  name = "${local.project}-netb-az1"
}

data "opentelekomcloud_networking_network_v2" "netb-az2" {
  name = "${local.project}-netb-az2"
}

data "opentelekomcloud_networking_network_v2" "netc-az1" {
  name = "${local.project}-netc-az1"
}

data "opentelekomcloud_networking_network_v2" "netc-az2" {
  name = "${local.project}-netc-az2"
}

data "opentelekomcloud_vpc_subnet_v1" "subneta_az1" {
  name = "${local.project}-subneta_az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subneta_az2" {
  name = "${local.project}-subneta_az2"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetb_az1" {
  name = "${local.project}-subnetb_az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetb_az2" {
  name = "${local.project}-subnetb_az2"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetc_az1" {
  name = "${local.project}-subnetc_az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetc_az2" {
  name = "${local.project}-subnetc_az2"
}

#data "opentelekomcloud_vpc_subnet_ids_v1" "subnet_ids" {
#  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
#}

# do not manage nets but use datasources because its
#resource "opentelekomcloud_vpc_subnet_v1" "neta-az1" {
#  name = "${local.project}-prod-az1"
#  cidr              = module.variables.subnet_cidr["prod-az1"]
#  gateway_ip        = module.variables.gateway["prod-az1"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-01"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}
#
#resource "opentelekomcloud_vpc_subnet_v1" "prod-az2" {
#  name = "${local.project}-prod-az2"
#  cidr              = module.variables.subnet_cidr["prod-az2"]
#  gateway_ip        = module.variables.gateway["prod-az2"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-02"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}
#
## cannot currently have spare because no room left on test tenant
##resource "opentelekomcloud_vpc_subnet_v1" "netb-az1" {
##  name = "${local.project}-netb-az1"
##  cidr              = module.variables.subnet_cidr["netb-az1"]
##  gateway_ip        = module.variables.gateway["netb-az1"]
##  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
##  availability_zone = "eu-ch-01"
##  primary_dns       = "100.125.4.25"
##  secondary_dns     = "100.125.0.43"
##}
##
##resource "opentelekomcloud_vpc_subnet_v1" "netb-az2" {
##  name = "${local.project}-netb-az2"
##  cidr              = module.variables.subnet_cidr["netb-az2"]
##  gateway_ip        = module.variables.gateway["netb-az2"]
##  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
##  availability_zone = "eu-ch-02"
##  primary_dns       = "100.125.4.25"
##  secondary_dns     = "100.125.0.43"
##}
#
#resource "opentelekomcloud_vpc_subnet_v1" "netc-az1" {
#  name = "${local.project}-netc-az1"
#  cidr              = module.variables.subnet_cidr["netc-az1"]
#  gateway_ip        = module.variables.gateway["netc-az1"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-01"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}
#
#resource "opentelekomcloud_vpc_subnet_v1" "netc-az2" {
#  name = "${local.project}-netc-az2"
#  cidr              = module.variables.subnet_cidr["netc-az2"]
#  gateway_ip        = module.variables.gateway["netc-az2"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-02"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}

#resource "opentelekomcloud_networking_router_interface_v2" "router-interface-az1" {
#  router_id = data.opentelekomcloud_vpc_v1.vpc.id
#  subnet_id = data.opentelekomcloud_vpc_subnet_v1.subnet_az1.id
#}



