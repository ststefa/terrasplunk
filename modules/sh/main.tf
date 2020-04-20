locals {
  stage = substr(var.instance_name, 3, 2)
}

module "variables" {
  source = "../../modules/variables"

  workspace = terraform.workspace
  stage     = local.stage
}

data "terraform_remote_state" "shared" {
  #backend = "local"
  #config = {
  #  path = module.variables.shared_statefile
  #}
  backend = "s3"
  config = module.variables.s3_shared_config
}

module "sh-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_sh
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.searchhead-secgrp_id]
}

resource "opentelekomcloud_blockstorage_volume_v2" "kvstore" {
  availability_zone = module.sh-instance.az
  name              = "${module.sh-instance.name}-kvstore"
  size              = module.variables.pvsize_kvstore
  volume_type       = "SSD"
}

resource "opentelekomcloud_compute_volume_attach_v2" "kvstore_attach" {
  instance_id = module.sh-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.kvstore.id
}
