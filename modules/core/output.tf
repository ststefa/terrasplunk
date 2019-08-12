# Reference by name instead of id, see https://www.terraform.io/docs/providers/opentelekomcloud/r/compute_secgroup_v2.html#referencing-security-groups
output "base-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.base-secgrp.name
}
output "indexer-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.indexer-secgrp.name
}
output "searchhead-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.searchhead-secgrp.name
}
output "parser-secgrp_id" {
  value = opentelekomcloud_compute_secgroup_v2.parser-secgrp.name
}
