locals {
  project     = "splunk"
  tenant_name = terraform.workspace == "default" ? "tsch_rz_t_001" : "tsch_rz_p_001"
}

terraform {
  required_version = ">= 0.12.29"
  backend "s3" {
    # Unfortunately interpolations are not allowed in backend config
    profile = "sbb-splunk"
    bucket  = "sbb-splunkterraform-prod"
    region  = "eu-central-1"
    # Manually name it like the parent dir.
    # ATTENTION! Do not mess this up! You might destroy another stages state!
    key            = "shared.tfstate"
    acl            = "private"
    dynamodb_table = "splunkterraform"
  }
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  #user_name   = var.username
  #password    = var.password
  cloud    = module.variables.tenant
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

# TODO: Maybe refactor variables in two mods? see TODO there
module "variables" {
  source    = "../modules/variables"
  workspace = terraform.workspace
  stage     = "dontcare"
}

resource "opentelekomcloud_compute_keypair_v2" "keypair-tss" {
  name       = "${local.project}-tss-key"
  public_key = file("../lib/splunk-otc.pub")
}

# network and security group settings were moved to separate files to aid readability
