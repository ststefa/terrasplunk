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

module "ix-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_ix
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.indexer-secgrp_id, data.terraform_remote_state.shared.outputs.rest4someip-secgrp_id]
}

resource "openstack_blockstorage_volume_v3" "cold1" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-cold1"
  size                 = module.variables.pvsize_cold
  enable_online_resize = true
  #TODO: add lifecycle {prevent_destroy = true} for all pvs?
}
resource "openstack_blockstorage_volume_v3" "cold2" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-cold2"
  size                 = module.variables.pvsize_cold
  enable_online_resize = true
}
resource "openstack_blockstorage_volume_v3" "cold3" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-cold3"
  size                 = module.variables.pvsize_cold
  enable_online_resize = true
}
resource "openstack_blockstorage_volume_v3" "cold4" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-cold4"
  size                 = module.variables.pvsize_cold
  enable_online_resize = true
}

resource "openstack_blockstorage_volume_v3" "hot1" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-hot1"
  size                 = module.variables.pvsize_hot
  volume_type          = "SSD"
  enable_online_resize = true
}
resource "openstack_blockstorage_volume_v3" "hot2" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-hot2"
  size                 = module.variables.pvsize_hot
  volume_type          = "SSD"
  enable_online_resize = true
}
resource "openstack_blockstorage_volume_v3" "hot3" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-hot3"
  size                 = module.variables.pvsize_hot
  volume_type          = "SSD"
  enable_online_resize = true
}
resource "openstack_blockstorage_volume_v3" "hot4" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-hot4"
  size                 = module.variables.pvsize_hot
  volume_type          = "SSD"
  enable_online_resize = true
}

resource "openstack_blockstorage_volume_v3" "splunkvar" {
  availability_zone    = module.ix-instance.az
  name                 = "${module.ix-instance.name}-splunkvar"
  size                 = module.variables.pvsize_splunkvar
  volume_type          = "SSD"
  enable_online_resize = true
}

resource "openstack_compute_volume_attach_v2" "cold1_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.cold1.id
  depends_on  = [module.ix-instance]
}
resource "openstack_compute_volume_attach_v2" "cold2_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.cold2.id
  depends_on  = [openstack_compute_volume_attach_v2.cold1_attach]
}
resource "openstack_compute_volume_attach_v2" "cold3_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.cold3.id
  depends_on  = [openstack_compute_volume_attach_v2.cold2_attach]
}
resource "openstack_compute_volume_attach_v2" "cold4_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.cold4.id
  depends_on  = [openstack_compute_volume_attach_v2.cold3_attach]
}

resource "openstack_compute_volume_attach_v2" "hot1_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.hot1.id
  depends_on  = [openstack_compute_volume_attach_v2.cold4_attach]
}
resource "openstack_compute_volume_attach_v2" "hot2_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.hot2.id
  depends_on  = [openstack_compute_volume_attach_v2.hot1_attach]
}
resource "openstack_compute_volume_attach_v2" "hot3_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.hot3.id
  depends_on  = [openstack_compute_volume_attach_v2.hot2_attach]
}
resource "openstack_compute_volume_attach_v2" "hot4_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.hot4.id
  depends_on  = [openstack_compute_volume_attach_v2.hot3_attach]
}

resource "openstack_compute_volume_attach_v2" "splunkvar_attach" {
  instance_id = module.ix-instance.id
  volume_id   = openstack_blockstorage_volume_v3.splunkvar.id
  depends_on  = [openstack_compute_volume_attach_v2.hot4_attach]
}
