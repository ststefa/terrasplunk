output "network1_id" {
  value = openstack_networking_network_v2.core1.id
}
output "network2_id" {
  value = openstack_networking_network_v2.core2.id
}

output "subnet1_id" {
  value = openstack_networking_subnet_v2.core1.id
}
output "subnet2_id" {
  value = openstack_networking_subnet_v2.core2.id
}

output "interface1" {
  value = openstack_networking_router_interface_v2.core1
}
output "interface2" {
  value = openstack_networking_router_interface_v2.core2
}

output "network_az1_id" {
  value = data.openstack_networking_network_v2.AppSvc_T_net_AZ1.id
}
output "network_az2_id" {
  value = data.openstack_networking_network_v2.AppSvc_T_net_AZ2.id
}

output "subnet_az1_id" {
  value = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ1.id
}
output "subnet_az2_id" {
  value = data.openstack_networking_subnet_v2.AppSvc_T_subnet_AZ2.id
}

#output "interface_az1_id" {
#  value = openstack_networking_router_interface_v2.AppSvc_T_net_AZ1.id
#}
#output "interface_az2_id" {
#  value = openstack_networking_router_interface_v2.AppSvc_T_net_AZ2.id
#}


output "keypair_id" {
  value = openstack_compute_keypair_v2.keypair.id
}

output "indexer-secgrp_id" {
  value = openstack_compute_secgroup_v2.indexer-secgrp.id
}