locals {
  stage   = "spielwiese"
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

module "core" {
  source = "../../modules/core"
  stage  = local.stage
}

module "searchhead1" {
  source = "../../modules/genericecs"
  name = "splw0sh00"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "searchhead2" {
  source = "../../modules/genericecs"
  name = "splw0sh01"
  secgrp_id = module.core.searchhead-secgrp_id
}

module "indexer1" {
  source = "../../modules/indexer"
  name = "splw0id00"
  secgrp_id = module.core.indexer-secgrp_id
}

module "indexer2" {
  source = "../../modules/indexer"
  name = "splw0id01"
  secgrp_id = module.core.indexer-secgrp_id
}

module "syslog1" {
  source = "../../modules/genericecs"
  name = "splw0sy00"
  secgrp_id = module.core.parser-secgrp_id
}

module "syslog2" {
  source = "../../modules/genericecs"
  name = "splw0sy01"
  secgrp_id = module.core.parser-secgrp_id
}
