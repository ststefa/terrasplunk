locals {
  stage = "blue"
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
  vmname = "idx-${local.stage}-1"
  az     = "eu-ch-01"

  keypair_id = module.core.keypair_id

  #ip = "10.104.198.138"
  #network_id = module.core.network_az1_id
  ip         = "10.0.1.11"
  network_id = module.core.network1_id
  interface  = module.core.interface1

  secgrp_id = module.core.indexer-secgrp_id
}

module "indexer2" {
  source = "../../modules/indexer"

  stage  = "${local.stage}"
  vmname = "idx-${local.stage}-2"
  az     = "eu-ch-02"

  keypair_id = module.core.keypair_id

  #ip = "10.104.198.171"
  #network_id = module.core.network_az2_id
  ip         = "10.0.2.12"
  network_id = module.core.network2_id
  interface  = module.core.interface2

  secgrp_id = module.core.indexer-secgrp_id
}

# az1
#10.104.198.132

# az2
#10.104.198.169