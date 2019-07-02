locals {
  project    = "splunk"
  dns_domain = "sbb.ch"
}

data "template_file" "cloudinit" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    hostname = "${var.vmname}"
    fqdn     = "${var.vmname}.${local.dns_domain}"
  }
}

resource "openstack_compute_instance_v2" "indexer" {
  availability_zone = var.az
  flavor_name       = var.flavor
  name              = var.vmname
  key_pair          = var.keypair_id
  user_data         = "${data.template_file.cloudinit.rendered}"
  security_groups   = [var.secgrp_id]

  network {
    uuid        = var.network_id
    fixed_ip_v4 = var.ip
  }
  # How to reference existing interfaces?? Theres no datasource, see core/main.tf
  #depends_on = [openstack_networking_router_interface_v2.AppSvc_T_interface_AZ1]
  depends_on = [var.interface]

  block_device {
    #uuid                  = "a2f304a0-93c4-4f29-a052-ce412381f1c9" # Enterprise_RedHat_7_latest
    uuid                  = "51951fc1-059e-4a7a-9906-ec08fd93a224" # Standard_CentOS_7_latest
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "openstack_blockstorage_volume_v2" "opt" {
  availability_zone = var.az
  name              = "indexer-opt"
  size              = 20
  #lifecycle {
  #  prevent_destroy = true
  #}
}
resource "openstack_blockstorage_volume_v2" "cold1" {
  availability_zone = var.az
  name              = "indexer-cold1"
  size              = 10
}
resource "openstack_blockstorage_volume_v2" "cold2" {
  availability_zone = var.az
  name              = "indexer-cold2"
  size              = 10
}
resource "openstack_blockstorage_volume_v2" "hot1" {
  availability_zone = var.az
  name              = "indexer-hot1"
  size              = 5
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot2" {
  availability_zone = var.az
  name              = "indexer-hot2"
  size              = 5
  volume_type       = "SSD"
}

resource "openstack_compute_volume_attach_v2" "opt_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.opt.id
  depends_on  = [openstack_compute_instance_v2.indexer]
}
resource "openstack_compute_volume_attach_v2" "cold1_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.cold1.id
  depends_on  = [openstack_compute_volume_attach_v2.opt_attach]
}
resource "openstack_compute_volume_attach_v2" "cold2_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.cold2.id
  depends_on  = [openstack_compute_volume_attach_v2.cold1_attach]
}
resource "openstack_compute_volume_attach_v2" "hot1_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot1.id
  depends_on  = [openstack_compute_volume_attach_v2.cold2_attach]
}
resource "openstack_compute_volume_attach_v2" "hot2_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot2.id
  depends_on  = [openstack_compute_volume_attach_v2.hot1_attach]
}

#resource "null_resource" "provisioner" {
#
#  triggers = {
#    cluster_instance_ids = openstack_compute_instance_v2.indexer.id
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "echo $(hostname -f) $(pwd) $(date) name=${openstack_compute_instance_v2.indexer.name} >> provisioned.txt",
#      "ls -la",
#      "cat provisioned.txt",
#    ]
#    connection {
#      type      = "ssh"
#      host      = openstack_compute_instance_v2.indexer.access_ip_v4
#      user      = "linux"
#      agent     = true
#      timeout   = "120s"
#    }
#  }
#}
