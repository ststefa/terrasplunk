locals {
  project = "splunk"
}

resource "openstack_compute_instance_v2" "indexer" {
  availability_zone = "${var.az}"
  flavor_name       = "${var.flavor}"
  name              = "${var.vmname}"
  key_pair          = openstack_compute_keypair_v2.keypair.id
  user_data         = "${data.template_file.provtest.rendered}"
  security_groups = [openstack_compute_secgroup_v2.secgrp.name]

  network {
    uuid = data.openstack_networking_network_v2.AppSvc_T_net_AZ1.id
    fixed_ip_v4 = "${var.ip}"
  }
  #depends_on = [openstack_networking_router_interface_v2.AppSvc_T_interface_AZ1]

  block_device {
    uuid                  = "a2f304a0-93c4-4f29-a052-ce412381f1c9" # Enterprise_RedHat_7_latest
    #uuid                  = "51951fc1-059e-4a7a-9906-ec08fd93a224" # Standard_CentOS_7_latest
    source_type           = "image"
    volume_size           = 50
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "null_resource" "provisioner" {

  triggers = {
    cluster_instance_ids = "${openstack_compute_instance_v2.provtest.id}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo $(hostname -f) $(pwd) $(date) name=${openstack_compute_instance_v2.provtest.name} >> provisioned.txt",
      "ls -la",
      "cat provisioned.txt",
    ]
    connection {
      type      = "ssh"
      host      = openstack_compute_instance_v2.provtest.access_ip_v4
      user      = "linux"
      agent     = true
      timeout   = "120s"
    }
  }
}
