locals {
  project    = "splunk"
  dns_domain = "sbb.ch"
}

data "template_file" "cloudinit" {
  template = "${file("${path.module}/templates/cloudinit.tpl")}"

  vars = {
    # cycle
    #hostname = "${openstack_compute_instance_v2.indexer.name}"
    hostname = "${var.name}"
    fqdn     = "${var.name}.${local.dns_domain}"
  }
}

resource "openstack_compute_instance_v2" "instance" {
  availability_zone = var.az
  flavor_name       = var.flavor
  name              = var.name
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
  availability_zone = var.az
  name              = "${var.name}-opt"
  size              = 20
  # mMaybe good idea as safety measure?
  #lifecycle {
  #  prevent_destroy = true
  #}
}

resource "openstack_compute_volume_attach_v2" "opt_attach" {
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = openstack_blockstorage_volume_v2.opt.id
  depends_on  = [openstack_compute_instance_v2.instance]
}

resource "null_resource" "provisioner" {

  triggers = {
    ecs_id = openstack_compute_instance_v2.instance.id
  }

  provisioner "remote-exec" {
    inline = [
      "echo $(hostname -f) $(pwd) $(date) name=${openstack_compute_instance_v2.instance.name} >> provisioned.txt",
      "cat provisioned.txt",
    ]
    connection {
      type      = "ssh"
      host      = openstack_compute_instance_v2.instance.access_ip_v4
      user      = "linux"
      agent     = true
      timeout   = "120s"
    }
  }
}
