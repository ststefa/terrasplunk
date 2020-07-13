locals {
  # Take stage from hostname (e.g. "w0")
  stage = substr(var.instance_name, 3, 2)

  # Host number are the last three digits from hostname (e.g. "000)
  hostnumber = tonumber(substr(var.instance_name, -3, 3))

  # Even numbers are placed in AZ1 (openstack name eu-ch-01). Odd numbers are placed in AZ2 (openstack name eu-ch-02).
  availability_zone = local.hostnumber % 2 == 0 ? "eu-ch-01" : "eu-ch-02"

  # g0, p0 and h0 is in netA, everything else in netC. More logic required if we extend to netB
  netname = local.stage == "p0" || local.stage == "h0" || local.stage == "g0" ? "netA" : "netC"

  # The remote shared state exports the nets by these names
  network_id = local.hostnumber % 2 == 0 ? data.terraform_remote_state.shared.outputs["${local.netname}-az1_id"] : data.terraform_remote_state.shared.outputs["${local.netname}-az2_id"]
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

data "opentelekomcloud_images_image_v2" "osimage" {
  #name        = "Standard_CentOS_7_latest"
  #name        = "Standard_CentOS_7_prev"
  name        = "Standard_CentOS_7_r7.7.1980"
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
  # Give OS daemons time to shutdown. Does not seem to work
  stop_before_destroy = true
  # sometimes instance are not deleted causing problems with recreation (IP still claimed)
  # However: "Error: Unsupported argument" although documented on https://www.terraform.io/docs/providers/opentelekomcloud/r/compute_instance_v2.html
  #force_delete        = true

  # Tagging does not work on OTC. See terraform project https://gitlab-tss.sbb.ch/splunk/otctagtest for in depth details
  #tag = {
  #  application = "splunk"
  #}

  # SBB required metadata as per https://issues.sbb.ch/browse/UOS-112
  metadata = {
    sbb_accounting_number    = "70031944"
    sbb_infrastructure_stage = module.variables.sbb_infrastructure_stage
    sbb_mega_id              = "8FD790A15E212AEF"
    sbb_requester            = "ursula.buehlmann@sbb.ch"
    sbb_os                   = "linux"
    sbb_contact              = "ursula.buehlmann@sbb.ch"
    sbb_sla                  = module.variables.tenant == "tsch_rz_t_001" ? "none" : "2b"
    uos_managed              = module.variables.tenant == "tsch_rz_t_001" ? "false" : "true"
    uos_group                = "DG_RBT_UOS_ADMIN"
    uos_monitoring           = module.variables.tenant == "tsch_rz_t_001" ? "false" : "true"
    splunk_stage             = local.stage
  }

  network {
    uuid        = local.network_id
    fixed_ip_v4 = module.variables.pmdns_list[var.instance_name]
  }
  #depends_on = [var.interface]

  # using a nested blockstorage inside compute_instance is also possible but resulted in mixed up vda/vdb assignments in some cases (i.e. root=vdb, opt=vda). Using externally defined blockstorage instead with explicit dependencies in opt_attach to make sure opt is not assigned before the root disk
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
