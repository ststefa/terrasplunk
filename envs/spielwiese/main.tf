locals {
  workspace = "spielwiese"
  # Might introduce workspaces instead of multiple envs/ dirs for more DRYness. However see discussion at https://www.terraform.io/docs/state/workspaces.html
  # See also ideas at https://medium.com/capital-one-tech/deploying-multiple-environments-with-terraform-kubernetes-7b7f389e622
  #workspace = terraform.workspace
}

# TODO: move all env-specifics to modules/variables to make more DRY. But how to handle verying amount of instances by stage (e.g. #idx(int) != #idx(prod))? Maybe dynmaic based on contents in mod/var.

module "variables" {
  source = "../../modules/variables"

  workspace  = local.workspace
  #workspace  = terraform.workspace
}

module "core" {
  source = "../../modules/core"

  dns_servers  = ["100.125.4.25", "100.125.0.43"]
  stage        = module.variables.stage
  subnet_cidr1 = "10.0.1.0/24"
  subnet_cidr2 = "10.0.2.0/24"
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

terraform {
  required_version = ">= 0.12"
}
