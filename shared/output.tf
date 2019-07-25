output "neta-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.neta-az1.id
}
output "neta-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.neta-az2.id
}
#output "netb-az1_id" {
#  value = data.opentelekomcloud_networking_network_v2.netb-az1.id
#}
#output "netb-az2_id" {
#  value = data.opentelekomcloud_networking_network_v2.netb-az2.id
#}
output "netc-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.netc-az1.id
}
output "netc-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.netc-az2.id
}

output "subneta-az1_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subneta_az1.subnet_id
}
output "subneta-az2_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subneta_az2.subnet_id
}
#output "subnetb-az1_id" {
#  value = data.opentelekomcloud_vpc_subnet_v1.subnetb_az1.subnet_id
#}
#output "subnetb-az2_id" {
#  value = data.opentelekomcloud_vpc_subnet_v1.subnetb_az2.subnet_id
#}
output "subnetc-az1_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetc_az1.subnet_id
}
output "subnetc-az2_id" {
  value = data.opentelekomcloud_vpc_subnet_v1.subnetc_az2.subnet_id
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
