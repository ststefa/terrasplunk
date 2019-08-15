locals {
  stage             = substr(var.name, 3, 2)
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

# see comment on nested instance blockstorage
resource "opentelekomcloud_blockstorage_volume_v2" "root" {
  name              = "${var.name}-root"
  availability_zone = local.availability_zone
  size              = module.variables.pvsize_root
  image_id          = data.opentelekomcloud_images_image_v2.osimage.id
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  availability_zone = local.availability_zone
  flavor_name       = module.variables.flavor
  name              = var.name
  key_pair          = data.terraform_remote_state.shared.outputs["keypair-tss_id"]
  # Attention! Any change (even comments) to user_data will rebuild the VM. Use only for the most stable and basic tasks!
  #user_data         = "${data.template_file.provtest.rendered}"
  security_groups = setunion([data.terraform_remote_state.shared.outputs["base-secgrp_id"]], var.secgrp_id_list)
  auto_recovery   = var.autorecover
  # Give OS daemons time to shutdown
  stop_before_destroy = true
  # sometimes instance are not deleted causing problems with recreation (IP still claimed)
  # However: "Error: Unsupported argument" although documented on https://www.terraform.io/docs/providers/opentelekomcloud/r/compute_instance_v2.html
  #force_delete        = true

  network {
    uuid        = local.network_id
    fixed_ip_v4 = module.variables.pmdns[var.name]
  }
  #depends_on = [var.interface]

  # using a nested blockstorage is also possible but resulted in mixed up vda/vdb assignments in some cases. Using externally defined blockstorage instead with additional dependencies for attach.opt
  block_device {
    uuid        = opentelekomcloud_blockstorage_volume_v2.root.id
    source_type = "volume"
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
  # Sometimes leads to swapped vda<>vdb
  #depends_on = [opentelekomcloud_compute_instance_v2.instance]
  depends_on = [opentelekomcloud_compute_instance_v2.instance, opentelekomcloud_blockstorage_volume_v2.root]
}

data "template_file" "provtest" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    fqdn     = "${var.name}.sbb.ch"
    hostname = "${var.name}"
  }
}
