locals {
  project = "splunk"
}

terraform {
  required_version = ">= 0.12"
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  #delegated_project = "eu-ch_splunk"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

module "variables" {
  source    = "../modules/variables"
  workspace = terraform.workspace
  stage     = "dontcare"
}

data "opentelekomcloud_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "${local.project}-vpc"
}

data "opentelekomcloud_networking_network_v2" "netA-az1" {
  name = "${local.project}-netA-az1"
}

data "opentelekomcloud_networking_network_v2" "netA-az2" {
  name = "${local.project}-netA-az2"
}

#data "opentelekomcloud_networking_network_v2" "netB-az1" {
#  name = "${local.project}-netB-az1"
#}
#
#data "opentelekomcloud_networking_network_v2" "netB-az2" {
#  name = "${local.project}-netB-az2"
#}

data "opentelekomcloud_networking_network_v2" "netC-az1" {
  name = "${local.project}-netC-az1"
}

data "opentelekomcloud_networking_network_v2" "netC-az2" {
  name = "${local.project}-netC-az2"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetA_az1" {
  name = "${local.project}-subnetA-az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetA_az2" {
  name = "${local.project}-subnetA-az2"
}

#data "opentelekomcloud_vpc_subnet_v1" "subnetB_az1" {
#  name = "${local.project}-subnetB-az1"
#}
#
#data "opentelekomcloud_vpc_subnet_v1" "subnetB_az2" {
#  name = "${local.project}-subnetB-az2"
#}

data "opentelekomcloud_vpc_subnet_v1" "subnetC_az1" {
  name = "${local.project}-subnetC-az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnetC_az2" {
  name = "${local.project}-subnetC-az2"
}

#data "opentelekomcloud_vpc_subnet_ids_v1" "subnet_ids" {
#  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
#}

# do not manage nets but use datasources because its
#resource "opentelekomcloud_vpc_subnet_v1" "netA-az1" {
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
##resource "opentelekomcloud_vpc_subnet_v1" "netB-az1" {
##  name = "${local.project}-netB-az1"
##  cidr              = module.variables.subnet_cidr["netB-az1"]
##  gateway_ip        = module.variables.gateway["netB-az1"]
##  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
##  availability_zone = "eu-ch-01"
##  primary_dns       = "100.125.4.25"
##  secondary_dns     = "100.125.0.43"
##}
##
##resource "opentelekomcloud_vpc_subnet_v1" "netB-az2" {
##  name = "${local.project}-netB-az2"
##  cidr              = module.variables.subnet_cidr["netB-az2"]
##  gateway_ip        = module.variables.gateway["netB-az2"]
##  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
##  availability_zone = "eu-ch-02"
##  primary_dns       = "100.125.4.25"
##  secondary_dns     = "100.125.0.43"
##}
#
#resource "opentelekomcloud_vpc_subnet_v1" "netC-az1" {
#  name = "${local.project}-netC-az1"
#  cidr              = module.variables.subnet_cidr["netC-az1"]
#  gateway_ip        = module.variables.gateway["netC-az1"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-01"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}
#
#resource "opentelekomcloud_vpc_subnet_v1" "netC-az2" {
#  name = "${local.project}-netC-az2"
#  cidr              = module.variables.subnet_cidr["netC-az2"]
#  gateway_ip        = module.variables.gateway["netC-az2"]
#  vpc_id            = data.opentelekomcloud_vpc_v1.vpc.id
#  availability_zone = "eu-ch-02"
#  primary_dns       = "100.125.4.25"
#  secondary_dns     = "100.125.0.43"
#}

#resource "opentelekomcloud_networking_router_interface_v2" "router-interface-az1" {
#  router_id = data.opentelekomcloud_vpc_v1.vpc.id
#  subnet_id = data.opentelekomcloud_vpc_subnet_v1.subnet_az1.id
#}


resource "opentelekomcloud_compute_keypair_v2" "keypair-tss" {
  name       = "${local.project}-tss-key"
  public_key = file("../lib/splunk-otc.pub")
}

