locals {
  # Take stage from hostname (e.g. "w0")
  stage = substr(var.instance_name, 3, 2)

  # Host number are the last three digits from hostname (e.g. "000)
  hostnumber = tonumber(substr(var.instance_name, -3, 3))

  # Even numbers are placed in AZ1 (openstack name eu-ch-01). Odd numbers are placed in AZ2 (openstack name eu-ch-02).
  availability_zone = local.hostnumber % 2 == 0 ? "eu-ch-01" : "eu-ch-02"

  # p0 is in netA, everything else in netC. More logic required if we extend to netB
  netname = local.stage == "p0" ? "netA" : "netC"

  # The remote shared state exports the nets by these names
  network_id = local.hostnumber % 2 == 0 ? data.terraform_remote_state.shared.outputs["${local.netname}-az1_id"] : data.terraform_remote_state.shared.outputs["${local.netname}-az2_id"]
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
  name              = "${var.instance_name}-root"
  availability_zone = local.availability_zone
  size              = module.variables.pvsize_root
  image_id          = data.opentelekomcloud_images_image_v2.osimage.id
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  availability_zone = local.availability_zone
  #TODO: would make sense to validate flavor name against OTC data?
  flavor_name = var.flavor == "unset" ? module.variables.flavor_default : var.flavor
  name        = var.instance_name
  key_pair    = data.terraform_remote_state.shared.outputs["keypair-tss_id"]
  # Attention! Any change (even comments) to user_data will rebuild the VM. Use only for the most stable and basic tasks!
  user_data = data.template_file.provtest.rendered
  # every instance gets base-secgrp_id plus additional secgroups if defined in the type
  security_groups = setunion([
  data.terraform_remote_state.shared.outputs["base-secgrp_id"]], var.secgrp_id_list)
  auto_recovery = var.autorecover
  # Give OS daemons time to shutdown
  stop_before_destroy = true
  # sometimes instance are not deleted causing problems with recreation (IP still claimed)
  # However: "Error: Unsupported argument" although documented on https://www.terraform.io/docs/providers/opentelekomcloud/r/compute_instance_v2.html
  #force_delete        = true

  # Attempting to tag results in:
  # Error: Error fetching OpenTelekomCloud instance tags: Resource not found: [GET https://ecs.eu-ch.o13bb.otc.t-systems.com/v1/530ba6eaa121424fa485c4b983d81924/servers/c57f7b80-a5de-4b0a-9786-7121c22f126e/tags], error message: {"message":"API not found","request_id":"0d04f437a9062ae60dbe2e1281fc7aa0"}
  # ATTENTION! The attempt to add a tag resulted in unusable terraform statefile. All tag sections had to be manually null-ed
  #tag = {
  #  application = "splunk"
  #}

  network {
    uuid        = local.network_id
    fixed_ip_v4 = module.variables.pmdns_list[var.instance_name]
  }
  #depends_on = [var.interface]

  # using a nested blockstorage is also possible but resulted in mixed up vda/vdb assignments in some cases (i.e. root=vdb, opt=vda). Using externally defined blockstorage instead with additional dependencies in opt_attach to make sure opt is not assigned before the root disk
  block_device {
    uuid                  = opentelekomcloud_blockstorage_volume_v2.root.id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "opentelekomcloud_blockstorage_volume_v2" "opt" {
  availability_zone = local.availability_zone
  name              = "${var.instance_name}-opt"
  size              = module.variables.pvsize_opt
}

resource "opentelekomcloud_compute_volume_attach_v2" "opt_attach" {
  instance_id = opentelekomcloud_compute_instance_v2.instance.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.opt.id
  # Sometimes leads to swapped vda<>vdb
  #depends_on = [opentelekomcloud_compute_instance_v2.instance]
  depends_on = [
    opentelekomcloud_compute_instance_v2.instance,
  opentelekomcloud_blockstorage_volume_v2.root]
}

data "template_file" "provtest" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    fqdn     = "${var.instance_name}.splunk.sbb.ch"
    hostname = "${var.instance_name}"
  }
}
