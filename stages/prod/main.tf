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

module "server-mt00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0mt00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-sh00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-sh01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh01"
  secgrp_id = module.core.searchhead-secgrp_id
}
module "server-sh02" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sh02"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-cm00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0cm00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-id00" {
  source = "../../modules/indexer"
  name = "${local.prefix}0id00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-id01" {
  source = "../../modules/indexer"
  name = "${local.prefix}0id01"
  secgrp_id = module.core.searchhead-secgrp_id
}
module "server-id02" {
  source = "../../modules/indexer"
  name = "${local.prefix}0id02"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-id03" {
  source = "../../modules/indexer"
  name = "${local.prefix}0id03"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-hf00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0hf00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-hf01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0hf01"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-sy00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "server-sy01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy01"
  secgrp_id = module.core.searchhead-secgrp_id
}
