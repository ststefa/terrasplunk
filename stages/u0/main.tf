terraform {
  required_version = ">= 0.12.21"
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
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
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

module "server-sh000" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh000"
}
module "server-sh001" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh001"
}
module "server-sh002" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh002"
}
