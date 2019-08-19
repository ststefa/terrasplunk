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
module "server-0sh03" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh03"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}
module "server-0sh04" {
  source         = "../../modules/genericecs"
  name           = "${local.prefix}sh04"
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}

module "server-0cm00" {
  source = "../../modules/genericecs"
  name   = "${local.prefix}cm00"
}
module "server-0ix00" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix00"
}
module "server-0ix01" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix01"
}
module "server-0ix02" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix02"
}
module "server-0ix03" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix03"
}
module "server-0ix04" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix04"
}
module "server-0ix05" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix05"
}
module "server-0ix06" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix06"
}
module "server-0ix07" {
  source = "../../modules/ix"
  name   = "${local.prefix}ix07"
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
