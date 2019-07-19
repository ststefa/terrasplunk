output "id" {
  description = "vm id"
  value       = openstack_compute_instance_v2.instance.id
}
output "ip" {
  description = "access ip"
  value       = openstack_compute_instance_v2.instance.access_ip_v4
}
output "name" {
  description = "instance name"
  value       = openstack_compute_instance_v2.instance.name
}
#output "opt_attach" {
#  description = "attach.opt"
#  value       = openstack_compute_volume_attach_v2.opt_attach.device
#}

