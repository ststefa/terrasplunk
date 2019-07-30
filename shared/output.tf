output "netA-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.netA-az1.id
}
output "netA-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.netA-az2.id
}
#output "netB-az1_id" {
#  value = data.opentelekomcloud_networking_network_v2.netB-az1.id
#}
#output "netB-az2_id" {
#  value = data.opentelekomcloud_networking_network_v2.netB-az2.id
#}
output "netC-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.netC-az1.id
}
output "netC-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.netC-az2.id
}

output "subnetA-az1_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetA_az1.subnet_id
}
output "subnetA-az2_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetA_az2.subnet_id
}
#output "subnetB-az1_id" {
#  value = data.opentelekomcloud_vpc_subnet_v1.subnetB_az1.subnet_id
#}
#output "subnetB-az2_id" {
#  value = data.opentelekomcloud_vpc_subnet_v1.subnetB_az2.subnet_id
#}
output "subnetC-az1_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetC_az1.subnet_id
}
output "subnetC-az2_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetC_az2.subnet_id
}

#output "interface1" {
#  #value = opentelekomcloud_networking_router_interface_v2.router-interface-az1
#  value = ""
#}
#output "interface2" {
#  value = ""
#}

output "keypair-tss_id" {
  value = opentelekomcloud_compute_keypair_v2.keypair-tss.id
}
