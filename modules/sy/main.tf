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

module "sy-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_sy
  # sy systems need to be open for
  # - syslog
  # - splunkforwarder REST (see https://issues.sbb.ch/browse/MON-1566)
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.parser-secgrp_id, data.terraform_remote_state.shared.outputs.rest-secgrp_id]
}

resource "opentelekomcloud_blockstorage_volume_v2" "var" {
  availability_zone = module.sy-instance.az
  name              = "${module.sy-instance.name}-var"
  size              = module.variables.pvsize_var
  volume_type       = "SSD"
}

resource "opentelekomcloud_compute_volume_attach_v2" "var_attach" {
  instance_id = module.sy-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.var.id
  depends_on  = [module.sy-instance]
}
