locals {
  this_stage = "w"  # Substitute value for the environment ID
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

module "server-0ix00" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix00"
  secgrp_id = module.core.indexer-secgrp_id
}

module "server-0ix01" {
  source = "../../modules/indexer"
  name = "${local.prefix}0ix01"
  secgrp_id = module.core.indexer-secgrp_id
}

module "server-0ix01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy00"
  secgrp_id = module.core.parser-secgrp_id
}

module "server-0ix01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}0sy01"
  secgrp_id = module.core.parser-secgrp_id
}
