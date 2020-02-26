locals {
  stage = substr(var.instance_name, 3, 2)
}

module "variables" {
  source = "../../modules/variables"

  workspace = terraform.workspace
  stage     = local.stage
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = module.variables.shared_statefile
  }
}

module "ix-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_ix
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.indexer-secgrp_id]
}

resource "opentelekomcloud_blockstorage_volume_v2" "cold1" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-cold1"
  size              = module.variables.pvsize_cold
  #TODO: add lifecycle {prevent_destroy = true} for all pvs?
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold2" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-cold2"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold3" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-cold3"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold4" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-cold4"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot1" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-hot1"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot2" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-hot2"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot3" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-hot3"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot4" {
  availability_zone = module.ix-instance.az
  name              = "${module.ix-instance.name}-hot4"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}

resource "opentelekomcloud_compute_volume_attach_v2" "cold1_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold1.id
  depends_on  = [module.ix-instance]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold2_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold2.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold1_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold3_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold3.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold2_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold4_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold4.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold3_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot1_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot1.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold4_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot2_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot2.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot1_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot3_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot3.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot2_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot4_attach" {
  instance_id = module.ix-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot4.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot3_attach]
}
