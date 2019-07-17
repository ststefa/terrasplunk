locals {
  workspace = "spielwiese"
  # Might introduce workspaces instead of multiple envs/ dirs for more DRYness. However see discussion at https://www.terraform.io/docs/state/workspaces.html
  # See also ideas at https://medium.com/capital-one-tech/deploying-multiple-environments-with-terraform-kubernetes-7b7f389e622
  # workspaces might be a good idea to seperate between test/prod tenant:
  #   one seperate envs/ directory for each stage s/t/i/p
  #   two workspaces in each envs/* dir (prod and test for prod tenant and test tenant)
  # also set some provider values (e.g. tenant) based on mod/var to prevent errors
  # need to find wording to seperate t/p (tenant) axis from s/t/i/p (stage) axis
  #workspace = terraform.workspace
}

# TODO: move all env-specifics to modules/variables to make more DRY. But how to handle verying amount of instances by stage (e.g. #idx(int) != #idx(prod))? Maybe dynmaic based on contents in mod/var?
#TODO: Rewrite everthing from OpSt to OTC, kick OpSt provider

provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  user_name   = "ssteine2"
  password    = "4w8puELDteCC"
  #delegated_project = "eu-ch_splunk"
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "openstack" {
  domain_name = "tsch_rz_t_001"
  #tenant_name = "eu-ch"
  #user_name   = var.username
  #password    = var.password
  # use openstack cloud config (~/.config/openstack/clouds.yaml) instead of username/password
  # see
  # https://docs.openstack.org/python-openstackclient/stein/configuration/index.html
  cloud = "otc-sbb-t"
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "null" {
}


module "variables" {
  source = "../../modules/variables"

  workspace  = local.workspace
  #workspace  = terraform.workspace
}

module "core" {
  source = "../../modules/core"

  dns_servers  = ["100.125.4.25", "100.125.0.43"]
  stage        = module.variables.stage
  # OTC does not like /29. Too small
  #subnet_cidr1 = "10.104.146.240/29"
  #subnet_cidr2 = "10.104.146.248/29"
  subnet_cidr1 = "10.104.146.224/28"
  subnet_cidr2 = "10.104.146.240/28"
}

module "searchhead1" {
  source = "../../modules/genericecs"

  stage  = module.variables.stage
  name = "splk${module.variables.stage_letter}-sh01"

  keypair_id = module.core.keypair_id

  ip = module.variables.searchhead_ip_list[0]
  network_id = module.core.network1_id
  interface  = module.core.interface1
  az = "eu-ch-01"
  secgrp_id  = module.core.parser-secgrp_id
}

module "searchhead2" {
  source = "../../modules/genericecs"

  stage  = module.variables.stage
  name = "splk${module.variables.stage_letter}-sh02"

  keypair_id = module.core.keypair_id

  ip = module.variables.searchhead_ip_list[1]
  network_id = module.core.network2_id
  interface  = module.core.interface2
  az = "eu-ch-02"
  secgrp_id  = module.core.parser-secgrp_id
}

module "indexer1" {
  source = "../../modules/indexer"

  stage  = module.variables.stage
  number = "1"

  keypair_id = module.core.keypair_id

  ip = module.variables.indexer_ip_list[0]
  network_id = module.core.network1_id
  interface  = module.core.interface1
  secgrp_id  = module.core.indexer-secgrp_id
}

module "indexer2" {
  source = "../../modules/indexer"

  stage  = module.variables.stage
  number = "2"

  keypair_id = module.core.keypair_id

  ip = module.variables.indexer_ip_list[1]
  network_id = module.core.network2_id
  interface  = module.core.interface2
  secgrp_id  = module.core.indexer-secgrp_id
}

module "syslog1" {
  source = "../../modules/genericecs"

  stage  = module.variables.stage
  name = "splk${module.variables.stage_letter}-sy01"

  keypair_id = module.core.keypair_id

  ip = module.variables.syslog_ip_list[0]
  network_id = module.core.network1_id
  interface  = module.core.interface1
  az = "eu-ch-01"
  secgrp_id  = module.core.parser-secgrp_id
}

module "syslog2" {
  source = "../../modules/genericecs"

  stage  = module.variables.stage
  name = "splk${module.variables.stage_letter}-sy02"

  keypair_id = module.core.keypair_id

  ip = module.variables.syslog_ip_list[1]
  network_id = module.core.network2_id
  interface  = module.core.interface2
  az = "eu-ch-02"
  secgrp_id  = module.core.parser-secgrp_id
}

terraform {
  required_version = ">= 0.12"
}
