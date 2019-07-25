output "id" {
  description = "vm id"
  value       = opentelekomcloud_compute_instance_v2.instance.id
}
output "ip" {
  description = "access ip"
  value       = opentelekomcloud_compute_instance_v2.instance.access_ip_v4
}
output "name" {
  description = "instance name"
  value       = opentelekomcloud_compute_instance_v2.instance.name
}
output "az" {
  description = "availibility zone"
  value       = opentelekomcloud_compute_instance_v2.instance.availability_zone
}
#output "opt_attach" {
#  description = "attach.opt"
#  value       = opentelekomcloud_compute_volume_attach_v2.opt_attach.device
#}

