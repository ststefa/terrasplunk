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
  config  = module.variables.s3_shared_config
}

module "es-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_es
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.searchhead-secgrp_id]
}

resource "opentelekomcloud_blockstorage_volume_v2" "splunkvar" {
  availability_zone = module.es-instance.az
  name              = "${module.es-instance.name}-splunkvar"
  size              = module.variables.pvsize_splunkvar
  volume_type       = "SSD"
}

resource "opentelekomcloud_compute_volume_attach_v2" "splunkvar_attach" {
  instance_id = module.es-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.splunkvar.id
  depends_on  = [module.es-instance]
}
