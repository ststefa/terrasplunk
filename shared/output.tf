output "netA-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.netA-az1.id
}
output "subnetA-az1_id" {
  value = opentelekomcloud_vpc_subnet_v1.subnetA-az1.id
}

output "netA-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.netA-az2.id
}
output "subnetA-az2_id" {
  value = opentelekomcloud_vpc_subnet_v1.subnetA-az2.id
}

output "netB-az1_id" {
  # If there is an instance of it (i.e. count=1, see network.tf), then return it, else return a non-id literal intentionally causing terraform to fail on access
  value = length(data.opentelekomcloud_networking_network_v2.netB-az1[*].id) == 1 ? data.opentelekomcloud_networking_network_v2.netB-az1[0].id : "no-netB-az1"
  # simpler form does no longer work as of terraform 0.12.13
  #value = data.opentelekomcloud_networking_network_v2.netB-az1[0].id
}
output "subnetB-az1_id" {
  value = length(opentelekomcloud_vpc_subnet_v1.subnetB-az1[*].id) == 1 ? opentelekomcloud_vpc_subnet_v1.subnetB-az1[0].id : "no-subnetB-az1"
}

output "netB-az2_id" {
  value = length(data.opentelekomcloud_networking_network_v2.netB-az2[*].id) == 1 ? data.opentelekomcloud_networking_network_v2.netB-az2[0].id : "no-netB-az2"
}
output "subnetB-az2_id" {
  value = length(opentelekomcloud_vpc_subnet_v1.subnetB-az2[*].id) == 1 ? opentelekomcloud_vpc_subnet_v1.subnetB-az2[0].id : "no-subnetB-az2"
}

output "netC-az1_id" {
  value = data.opentelekomcloud_networking_network_v2.netC-az1.id
}
output "subnetC-az1_id" {
  value = opentelekomcloud_vpc_subnet_v1.subnetC-az1.id
}

output "netC-az2_id" {
  value = data.opentelekomcloud_networking_network_v2.netC-az2.id
}
output "subnetC-az2_id" {
  #value = data.opentelekomcloud_vpc_subnet_v1.subnetC_az2.subnet_id
  value = opentelekomcloud_vpc_subnet_v1.subnetC-az2.id
}

#output "interface1" {
#  #value = opentelekomcloud_networking_router_interface_v2.router-interface-az1
#  value = ""
#}
#output "interface2" {
#  value = ""
#}

# Reference secgroups name instead of id, see https://www.terraform.io/docs/providers/opentelekomcloud/r/compute_secgroup_v2.html#referencing-security-groups
# We should monitor whether this recommendation changes
output "base-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.base-secgrp.name
}
output "indexer-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.indexer-secgrp.name
}
output "rest4someip-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.rest4someip-secgrp_id.name
}
output "hec-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.hec-secgrp.name
}
output "searchhead-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.searchhead-secgrp.name
}
output "parser-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.parser-secgrp.name
}

output "keypair-tss_id" {
  value = opentelekomcloud_compute_keypair_v2.keypair-tss.id
}
