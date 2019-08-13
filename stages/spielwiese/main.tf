locals {
  this_stage = basename(abspath("${path.root}")) #TODO refactor, this.stage == basename("${path.root}")
  stage_map = {
    development : "d0"
    production : "p0"
    qa : "q0"
    test : "t0"
    universal : "u0"
    spielwiese : "w0"
  }
  stage  = local.stage_map[local.this_stage] #TODO refactor, stage == this.stage
  prefix = "spl${local.stage}"
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
  stage     = local.this_stage #TODO refactor, stage == this.stage
}

module "core" {
  source = "../../modules/core"
  stage  = local.this_stage #TODO refactor, stage == this.stage
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = module.variables.shared_statefile
  }
}

module "server-sh00" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh00"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}

module "server-sh01" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh01"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}

module "server-ix00" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix00"
}

module "server-ix01" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix01"
}

module "server-sy00" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sy00"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}

module "server-sy01" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sy01"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}
