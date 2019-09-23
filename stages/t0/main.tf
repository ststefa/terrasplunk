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

module "server-mt000" {
  source        = "../../modules/mt"
  instance_name = "${local.prefix}mt000"
}

module "server-cm000" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}cm000"
}

module "server-sh000" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh000"
}

module "server-ix000" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix000"
}
module "server-ix001" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix001"
}

module "server-hf000" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}hf000"
}

module "server-sy000" {
  source         = "../../modules/sy"
  instance_name  = "${local.prefix}sy000"
}
