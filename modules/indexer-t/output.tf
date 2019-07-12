output "ip" {
  description = "access ip"
  value       = openstack_compute_instance_v2.indexer.access_ip_v4
}
output "opt_attach" {
  description = "attach.opt"
  value       = openstack_compute_volume_attach_v2.opt_attach.device
}

