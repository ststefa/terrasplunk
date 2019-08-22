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
  source        = "../../modules/genericecs"
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
module "server-sh003" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh003"
}
module "server-sh004" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh004"
}

module "server-cm000" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}cm000"
}

module "server-ix000" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix000"
}
module "server-ix001" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix001"
}
module "server-ix002" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix002"
}
module "server-ix003" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix003"
}
module "server-ix004" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix004"
}
module "server-ix005" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix005"
}
module "server-ix006" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix006"
}
module "server-ix007" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix007"
}

module "server-hf000" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}hf000"
}
module "server-hf001" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}hf001"
}

module "server-sy000" {
  source         = "../../modules/sy"
  instance_name  = "${local.prefix}sy000"
}
module "server-sy001" {
  source         = "../../modules/sy"
  instance_name  = "${local.prefix}sy001"
}
