locals {
  stage = "spielwiese"
  indexer_ip = ["10.104.198.138",
                "10.104.198.171",
                "10.104.198.132",
                "10.104.198.169"]
  parser_ip = ["10.104.198.150",
                "10.104.198.182"]
}

module "variables" {
  source = "../../modules/variables"

  stage  = local.stage
}

module "core" {
  source = "../../modules/core"

  dns_servers  = ["100.125.4.25", "100.125.0.43"]
  stage        = "${local.stage}"
  subnet_cidr1 = "10.0.1.0/24"
  subnet_cidr2 = "10.0.2.0/24"
}

module "indexer1" {
  source = "../../modules/indexer"

  stage  = "${local.stage}"
  number = "1"

  keypair_id = module.core.keypair_id

  ip = local.indexer_ip[0]
  network_id = module.core.network_az1_id
  interface  = ""
  #ip         = "10.0.1.11"
  #network_id = module.core.network1_id
  #interface  = module.core.interface1
  secgrp_id  = module.core.indexer-secgrp_id
}

module "indexer2" {
  source = "../../modules/indexer"

  stage  = "${local.stage}"
  number = "2"

  keypair_id = module.core.keypair_id

  ip = local.indexer_ip[1]
  network_id = module.core.network_az2_id
  interface  = ""
  #ip         = "10.0.2.12"
  #network_id = module.core.network2_id
  #interface  = module.core.interface2
  secgrp_id  = module.core.indexer-secgrp_id
}

module "parser1" {
  source = "../../modules/genericecs"

  stage  = "${local.stage}"
  name = "splk${module.variables.stage_letter}-sy01"

  keypair_id = module.core.keypair_id

  ip = module.variables.syslog_ip_list[0]
  network_id = module.core.network_az1_id
  interface  = ""
  az = "eu-ch-01"
  #ip         = "10.0.2.12"
  #network_id = module.core.network2_id
  #interface  = module.core.interface2
  secgrp_id  = module.core.parser-secgrp_id
}

terraform {
  required_version = ">= 0.12"
}
