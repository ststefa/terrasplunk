output "network1_id" {
  value = data.opentelekomcloud_networking_network_v2.net-az1.id
}
output "network2_id" {
  value = data.opentelekomcloud_networking_network_v2.net-az2.id
}

output "subnet1_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnet_az1.subnet_id
}
output "subnet2_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnet_az2.subnet_id
}

output "interface1" {
  #value = opentelekomcloud_networking_router_interface_v2.router-interface-az1
  value = ""
}
output "interface2" {
  value = ""
}

output "keypair_id" {
  value = openstack_compute_keypair_v2.keypair.id
}

# Reference by name instead of id, see https://www.terraform.io/docs/providers/openstack/r/compute_secgroup_v2.html#referencing-security-groups
output "indexer-secgrp_id" {
  value = openstack_compute_secgroup_v2.indexer-secgrp.name
}
output "searchhead-secgrp_id" {
  value = openstack_compute_secgroup_v2.searchhead-secgrp.name
}
output "parser-secgrp_id" {
  value = openstack_compute_secgroup_v2.parser-secgrp.name
}
