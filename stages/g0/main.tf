terraform {
  required_version = ">= 0.12.21"
  backend "s3" {
    # Unfortunately interpolations are not allowed in backend config
    profile = "sbb-splunk"
    bucket  = "sbb-splunkterraform-prod"
    region  = "eu-central-1"
    # Manually name it like the parent dir.
    # ATTENTION! Do not mess this up! You might destroy another stages state!
    key            = "g0.tfstate"
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
  cloud       = module.variables.tenant
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "openstack" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  cloud       = module.variables.tenant
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

module "server-lm000" {
  source        = "../../modules/lm"
  instance_name = "${local.prefix}lm000"
}
