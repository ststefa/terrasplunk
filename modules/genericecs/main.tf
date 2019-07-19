module "variables" {
  source = "../../modules/variables"

  workspace  = terraform.workspace
  stage      = var.stage
}

module "core" {
  source = "../../modules/core"

  stage        = var.stage
}

data "opentelekomcloud_images_image_v2" "osimage" {
  name        = "Standard_CentOS_7_latest"
  most_recent = true
}

resource "openstack_compute_instance_v2" "instance" {
  availability_zone = module.variables.hostconfig[var.name]["az"]
  flavor_name       = var.flavor
  name              = var.name
  key_pair          = module.core.keypair_id
  security_groups   = [var.secgrp_id]

  network {
    uuid        = var.network_id
    fixed_ip_v4 = module.variables.hostconfig[var.name]["ip"]
  }
  depends_on = [var.interface]

  block_device {
    uuid                  = data.opentelekomcloud_images_image_v2.osimage.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "openstack_blockstorage_volume_v2" "opt" {
  availability_zone = module.variables.hostconfig[var.name]["az"]
  name              = "${var.name}-opt"
  size              = 20
  lifecycle {
    prevent_destroy = true
  }
}

resource "openstack_compute_volume_attach_v2" "opt_attach" {
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = openstack_blockstorage_volume_v2.opt.id
  depends_on  = [openstack_compute_instance_v2.instance]
}
