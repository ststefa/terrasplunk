locals {
  this_stage = "p"  # Substitute value for the environment ID
  stage_map = {
    d : "development"
    p : "production"
    q : "qa"
    t : "test"
    u : "universal"
    w : "spielwiese"
  }
  stage   = local.stage_map[local.this_stage]
  prefix  = "spl${local.this_stage}"
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
  source    = "../../modules/variables"
  workspace = terraform.workspace
  stage     = local.stage
}

module "core" {
  source = "../../modules/core"
  stage  = local.stage
}

module "server-0mt00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0mt00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0sh00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0sh01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh01"
  secgrp_id = module.core.searchhead-secgrp_id
}
module "server-0sh02" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh02"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0cm00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0cm00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0ix00" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0ix01" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix01"
  secgrp_id = module.core.searchhead-secgrp_id
}
module "server-0ix02" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix02"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0ix03" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix03"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0hf00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0hf00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0hf01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0hf01"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0sy00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-0sy01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy01"
  secgrp_id = module.core.searchhead-secgrp_id
}
