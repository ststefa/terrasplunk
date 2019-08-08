locals {
  stage_map = {
    d : "development"
    p : "production"
    q : "qa"
    t : "test"
    u : "universal"
    w : "spielwiese"
  }
  stage             = local.stage_map[substr(var.name, 3, 1)]
  hostnumber        = tonumber(substr(var.name, -2, 2))
  availability_zone = local.hostnumber % 2 == 0 ? "eu-ch-01" : "eu-ch-02"
  netname           = local.stage == "production" ? "netA" : "netC"
  network_id        = local.hostnumber % 2 == 0 ? data.terraform_remote_state.shared.outputs["${local.netname}-az1_id"] : data.terraform_remote_state.shared.outputs["${local.netname}-az2_id"]
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

data "opentelekomcloud_images_image_v2" "osimage" {
  name        = "Standard_CentOS_7_latest"
  most_recent = true
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  availability_zone   = local.availability_zone
  flavor_name         = module.variables.flavor
  name                = var.name
  key_pair            = data.terraform_remote_state.shared.outputs["keypair-tss_id"]
  # Attention! Any change (even comments) to user_data will rebuild the VM. Use only for the most stable and basic tasks!
  #user_data         = "${data.template_file.provtest.rendered}"
  security_groups     = [var.secgrp_id]
  stop_before_destroy = true
  auto_recovery       = var.autorecover

  network {
    uuid        = local.network_id
    fixed_ip_v4 = module.variables.pmdns[var.name]
  }
  #depends_on = [var.interface]

  block_device {
    uuid                  = data.opentelekomcloud_images_image_v2.osimage.id
    source_type           = "image"
    volume_size           = module.variables.pvsize_root
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "opentelekomcloud_blockstorage_volume_v2" "opt" {
  availability_zone = local.availability_zone
  name              = "${var.name}-opt"
  size              = module.variables.pvsize_opt
}

resource "opentelekomcloud_compute_volume_attach_v2" "opt_attach" {
  instance_id = opentelekomcloud_compute_instance_v2.instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.opt.id
  depends_on  = [opentelekomcloud_compute_instance_v2.instance.block_device]
}

data "template_file" "provtest" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    fqdn = "${var.name}.sbb.ch"
    hostname = "${var.name}"
  }
}
