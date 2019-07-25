locals {
  stage = "qa"
}

terraform {
  required_version = ">= 0.12"
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
