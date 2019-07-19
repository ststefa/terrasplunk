locals {
  hot_size   = 5
  cold_size  = 10
}

module "variables" {
  source = "../../modules/variables"

  workspace  = terraform.workspace
  stage      = var.stage
}

module "idx-instance" {
  source = "../../modules/genericecs"
  stage  = var.stage
  name = "splk${module.variables.stage_letter}-id${format("%02d", var.number)}"
  network_id = var.network_id
  interface  =var.interface
  secgrp_id  = var.secgrp_id
}


resource "openstack_blockstorage_volume_v2" "opt" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-opt"
  size              = 20
  # mMaybe good idea as safety measure?
  #lifecycle {
  #  prevent_destroy = true
  #}
}
resource "openstack_blockstorage_volume_v2" "cold1" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-cold1"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold2" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-cold2"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold3" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-cold3"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold4" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-cold4"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "hot1" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-hot1"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot2" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-hot2"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot3" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-hot3"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot4" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${module.idx-instance.name}-hot4"
  size              = local.hot_size
  volume_type       = "SSD"
}

resource "openstack_compute_volume_attach_v2" "opt_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.opt.id
  depends_on  = [module.idx-instance]
}
resource "openstack_compute_volume_attach_v2" "cold1_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.cold1.id
  depends_on  = [openstack_compute_volume_attach_v2.opt_attach]
}
resource "openstack_compute_volume_attach_v2" "cold2_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.cold2.id
  depends_on  = [openstack_compute_volume_attach_v2.cold1_attach]
}
resource "openstack_compute_volume_attach_v2" "cold3_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.cold3.id
  depends_on  = [openstack_compute_volume_attach_v2.cold2_attach]
}
resource "openstack_compute_volume_attach_v2" "cold4_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.cold4.id
  depends_on  = [openstack_compute_volume_attach_v2.cold3_attach]
}
resource "openstack_compute_volume_attach_v2" "hot1_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.hot1.id
  depends_on  = [openstack_compute_volume_attach_v2.cold4_attach]
}
resource "openstack_compute_volume_attach_v2" "hot2_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.hot2.id
  depends_on  = [openstack_compute_volume_attach_v2.hot1_attach]
}
resource "openstack_compute_volume_attach_v2" "hot3_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.hot3.id
  depends_on  = [openstack_compute_volume_attach_v2.hot2_attach]
}
resource "openstack_compute_volume_attach_v2" "hot4_attach" {
  instance_id = module.idx-instance.id
  volume_id   = openstack_blockstorage_volume_v2.hot4.id
  depends_on  = [openstack_compute_volume_attach_v2.hot3_attach]
}
