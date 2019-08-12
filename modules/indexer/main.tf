locals {
  #hot_size  = 5
  #cold_size = 10
  stage_map = {
    d : "development"
    t : "test"
    q : "quality"
    p : "production"
    w : "spielwiese"
    u : "universal"
  }
  stage = local.stage_map[substr(var.name, 3, 1)]
}

module "variables" {
  source = "../../modules/variables"

  workspace = terraform.workspace
  stage     = local.stage
}

module "idx-instance" {
  source         = "../../modules/genericecs"
  name           = var.name
  secgrp_id_list = var.secgrp_id_list
}

resource "opentelekomcloud_blockstorage_volume_v2" "cold1" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-cold1"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold2" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-cold2"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold3" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-cold3"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "cold4" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-cold4"
  size              = module.variables.pvsize_cold
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot1" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-hot1"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot2" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-hot2"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot3" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-hot3"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}
resource "opentelekomcloud_blockstorage_volume_v2" "hot4" {
  availability_zone = module.idx-instance.az
  name              = "${module.idx-instance.name}-hot4"
  size              = module.variables.pvsize_hot
  volume_type       = "SSD"
}

resource "opentelekomcloud_compute_volume_attach_v2" "cold1_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold1.id
  depends_on  = [module.idx-instance]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold2_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold2.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold1_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold3_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold3.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold2_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "cold4_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.cold4.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold3_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot1_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot1.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.cold4_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot2_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot2.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot1_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot3_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot3.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot2_attach]
}
resource "opentelekomcloud_compute_volume_attach_v2" "hot4_attach" {
  instance_id = module.idx-instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.hot4.id
  depends_on  = [opentelekomcloud_compute_volume_attach_v2.hot3_attach]
}
