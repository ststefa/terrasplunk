locals {
  this_stage = "p0" # Substitute value for the environment ID
  stage_map = {
    d0 : "development"
    p0 : "production"
    q0 : "qa"
    t0 : "test"
    u0 : "universal"
    w0 : "spielwiese"
  }
  stage  = local.stage_map[local.this_stage]
  prefix = "spl${local.this_stage}"
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

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = module.variables.shared_statefile
  }
}

module "server-0mt00" {
  source = "../../modules/genericecs"
  name   = "${local.prefix}mt00"
}

module "server-0sh00" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh00"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}

module "server-0sh01" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh01"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}
module "server-0sh02" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh02"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}

module "server-0cm00" {
  source = "../../modules/genericecs"
  name   = "${local.prefix}cm00"
}

module "server-0ix00" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix00"
}

module "server-0ix01" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix01"
}
module "server-0ix02" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix02"
}

module "server-0ix03" {
  source = "../../modules/indexer"
  name   = "${local.prefix}ix03"
}

module "server-0hf00" {
  source = "../../modules/genericecs"
  name   = "${local.prefix}hf00"
}

module "server-0hf01" {
  source = "../../modules/genericecs"
  name   = "${local.prefix}hf01"
}

module "server-0sy00" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sy00"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}

module "server-0sy01" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sy01"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}
