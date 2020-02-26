locals {
  project     = "splunk"
  tenant_name = terraform.workspace == "default" ? "tsch_rz_t_001" : "tsch_rz_p_001"
}

terraform {
  required_version = ">= 0.12.21"
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  #delegated_project = "eu-ch_splunk"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

# TODO: refactor variables in two mods, see TODO there
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
