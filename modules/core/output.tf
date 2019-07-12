output "network1_id" {
  value = openstack_networking_network_v2.core1.id
#  value = data.openstack_networking_network_v2.AppSvc_T_net_AZ1.id
}
output "network2_id" {
  value = openstack_networking_network_v2.core2.id
#  value = data.openstack_networking_network_v2.AppSvc_T_net_AZ2.id
}

output "subnet1_id" {
  value = openstack_networking_subnet_v2.core1.id
#  value = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ1.id
}
output "subnet2_id" {
  value = openstack_networking_subnet_v2.core2.id
#  value = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ2.id
}

output "interface1" {
  value = openstack_networking_router_interface_v2.core1
#  value = openstack_networking_router_interface_v2.AppSvc_T_net_AZ1.id
}
output "interface2" {
  value = openstack_networking_router_interface_v2.core2
#  value = openstack_networking_router_interface_v2.AppSvc_T_net_AZ2.id
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
