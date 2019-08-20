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

module "server-mt00" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}mt000"
  flavor        = "s2.medium.4"
}

module "server-sh00" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh000"
}
module "server-sh01" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh001"
}
module "server-sh02" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh002"
}
module "server-sh03" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh003"
}
module "server-sh04" {
  source        = "../../modules/sh"
  instance_name = "${local.prefix}sh004"
}

module "server-cm00" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}cm000"
  flavor        = "s2.medium.4"
}

module "server-ix00" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix000"
}
module "server-ix01" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix001"
}
module "server-ix02" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix002"
}
module "server-ix03" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix003"
}
module "server-ix04" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix004"
}
module "server-ix05" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix005"
}
module "server-ix06" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix006"
}
module "server-ix07" {
  source        = "../../modules/ix"
  instance_name = "${local.prefix}ix007"
}

module "server-hf00" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}hf000"
  flavor        = "s2.medium.4"
}

module "server-hf01" {
  source        = "../../modules/genericecs"
  instance_name = "${local.prefix}hf001"
  flavor        = "s2.medium.4"
}

module "server-sy00" {
  source         = "../../modules/genericecs"
  instance_name  = "${local.prefix}sy000"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
  flavor         = "s2.medium.4"
}

module "server-sy01" {
  source         = "../../modules/genericecs"
  instance_name  = "${local.prefix}sy001"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["parser-secgrp_id"]]
  flavor         = "s2.medium.4"
}
