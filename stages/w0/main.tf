terraform {
  required_version = ">= 0.12.4"
}

locals {
  stage  = basename(abspath("${path.root}"))
  prefix = "spl${local.stage}"
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

module "server-sh00" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh00"
}

module "server-sh01" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh01"
}

module "server-ix00" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix00"
}

module "server-ix01" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix01"
}

module "server-sy00" {
  source         = "../../modules/genericecs"
  instance_name  = "${local.prefix}sy00"
  flavor         = "s2.medium.4"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}

module "server-sy01" {
  source         = "../../modules/genericecs"
  instance_name  = "${local.prefix}sy01"
  flavor         = "s2.medium.4"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
}
