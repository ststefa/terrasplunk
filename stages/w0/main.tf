terraform {
  required_version = ">= 0.12.21"
  backend "s3" {
    # Unfortunately interpolations are not allowed in backend config
    profile = "sbb-splunk"
    bucket  = "sbb-splunkterraform-prod"
    region  = "eu-central-1"
    # Manually name it like the parent dir.
    # ATTENTION! Do not mess this up! You might destroy another stages state!
    key            = "w0.tfstate"
    acl            = "private"
    dynamodb_table = "splunkterraform"
  }
}

locals {
  stage  = basename(abspath("${path.root}"))
  prefix = "spl${local.stage}"
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  #user_name   = var.username
  #password    = var.password
  cloud    = module.variables.tenant
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "openstack" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  cloud       = "tsch_rz_t_001"
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
  #backend = "local"
  #config = {
  #  path = module.variables.shared_statefile
  #}
  backend = "s3"
  config  = module.variables.s3_shared_config
}

module "server-mt000" {
  source        = "../../modules/mt"
  instance_name = "${local.prefix}mt000"
}

module "server-cm000" {
  source        = "../../modules/cm"
  instance_name = "${local.prefix}cm000"
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

module "server-es001" {
  source        = "../../modules/es"
  instance_name = "${local.prefix}es001"
}

module "server-si000" {
  source        = "../../modules/si"
  instance_name = "${local.prefix}si000"
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
  source        = "../../modules/hf"
  instance_name = "${local.prefix}hf000"
}

module "server-sy000" {
  source        = "../../modules/sy"
  instance_name = "${local.prefix}sy000"
}
