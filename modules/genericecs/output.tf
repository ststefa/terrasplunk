output "ip" {
  description = "access ip"
  value       = openstack_compute_instance_v2.instance.access_ip_v4
}
output "attach" {
  description = "attach.opt"
  value       = openstack_compute_volume_attach_v2.opt_attach.device
}

