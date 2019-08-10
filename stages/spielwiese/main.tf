locals {
  this_stage = "w0"  # Substitute value with stage name (e.g. "p0", "t1", ...)
  stage_map = {
    d : "development"
    p : "production"
    q : "qa"
    t : "test"
    u : "universal"
    w : "spielwiese"
  }
  stage   = local.stage_map["w"] #TODO refactor, stage == this.stage
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

module "server-sh00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}sh00"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.searchhead-secgrp_id]
}

module "server-sh01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}sh01"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.searchhead-secgrp_id]
}

module "server-ix00" {
  source = "../../modules/indexer"
  name = "${local.prefix}ix00"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.indexer-secgrp_id]
}

module "server-ix01" {
  source = "../../modules/indexer"
  name = "${local.prefix}ix01"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.indexer-secgrp_id]
}

module "server-sy00" {
  source = "../../modules/genericecs"
  name = "${local.prefix}sy00"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.parser-secgrp_id]
}

module "server-sy01" {
  source = "../../modules/genericecs"
  name = "${local.prefix}sy01"
  secgrp_id_list = [module.core.base-secgrp_id, module.core.parser-secgrp_id]
}
