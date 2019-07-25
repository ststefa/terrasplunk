locals {
  stage = "spielwiese"
}


module "variables" {
  source    = "../../modules/variables"
  workspace = terraform.workspace
  stage     = local.stage
}

provider "opentelekomcloud" {
  domain_name = module.variables.tenant
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  #delegated_project = "eu-ch_splunk"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "null" {
}


module "core" {
  source = "../../modules/core"
  stage  = local.stage
}

module "searchhead1" {
  source = "../../modules/genericecs"
  #stage  = local.stage
  name = "splw0sh01"
  #network_id = module.core.network1_id
  #interface  = module.core.interface1
  secgrp_id = module.core.searchhead-secgrp_id
}

module "indexer1" {
  source = "../../modules/indexer"
  stage  = local.stage
  number = "1"
  #network_id = module.core.network1_id
  #interface  = module.core.interface1
  secgrp_id = module.core.indexer-secgrp_id
}


terraform {
  required_version = ">= 0.12"
}
