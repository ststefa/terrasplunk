locals {
  project    = "splunk"
  dns_domain = "sbb.ch"
  hot_size   = 5
  cold_size  = 10
}

data "template_file" "cloudinit" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    # cycle
    #hostname = "${openstack_compute_instance_v2.indexer.name}"
    hostname = "idx-${var.stage}-${var.number}"
    fqdn     = "idx-${var.stage}-${var.number}.${local.dns_domain}"
  }
}

resource "openstack_compute_instance_v2" "indexer" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  flavor_name       = var.flavor
  name              = "idx-${var.stage}-${var.number}"
  key_pair          = var.keypair_id
  user_data         = "${data.template_file.cloudinit.rendered}"
  security_groups   = [var.secgrp_id]

  network {
    uuid        = var.network_id
    fixed_ip_v4 = var.ip
  }
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
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-opt"
  size              = 20
  # mMaybe good idea as safety measure?
  #lifecycle {
  #  prevent_destroy = true
  #}
}
resource "openstack_blockstorage_volume_v2" "cold1" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-cold1"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold2" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-cold2"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold3" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-cold3"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "cold4" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-cold4"
  size              = local.cold_size
}
resource "openstack_blockstorage_volume_v2" "hot1" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-hot1"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot2" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-hot2"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot3" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-hot3"
  size              = local.hot_size
  volume_type       = "SSD"
}
resource "openstack_blockstorage_volume_v2" "hot4" {
  availability_zone = "eu-ch-0${1 + (var.number + 1) % 2}"
  name              = "${openstack_compute_instance_v2.indexer.name}-hot4"
  size              = local.hot_size
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
resource "openstack_compute_volume_attach_v2" "cold3_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.cold3.id
  depends_on  = [openstack_compute_volume_attach_v2.cold2_attach]
}
resource "openstack_compute_volume_attach_v2" "cold4_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.cold4.id
  depends_on  = [openstack_compute_volume_attach_v2.cold3_attach]
}
resource "openstack_compute_volume_attach_v2" "hot1_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot1.id
  depends_on  = [openstack_compute_volume_attach_v2.cold4_attach]
}
resource "openstack_compute_volume_attach_v2" "hot2_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot2.id
  depends_on  = [openstack_compute_volume_attach_v2.hot1_attach]
}
resource "openstack_compute_volume_attach_v2" "hot3_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot3.id
  depends_on  = [openstack_compute_volume_attach_v2.hot2_attach]
}
resource "openstack_compute_volume_attach_v2" "hot4_attach" {
  instance_id = openstack_compute_instance_v2.indexer.id
  volume_id   = openstack_blockstorage_volume_v2.hot4.id
  depends_on  = [openstack_compute_volume_attach_v2.hot3_attach]
}

resource "null_resource" "provisioner" {

  triggers = {
    ecs_id = openstack_compute_instance_v2.indexer.id
  }

  provisioner "remote-exec" {
    inline = [
      "echo $(hostname -f) $(pwd) $(date) name=${openstack_compute_instance_v2.indexer.name} >> provisioned.txt",
      "cat provisioned.txt",
    ]
    connection {
      type      = "ssh"
      host      = openstack_compute_instance_v2.indexer.access_ip_v4
      user      = "linux"
      agent     = true
      timeout   = "120s"
    }
  }
}
