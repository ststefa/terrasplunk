output "ip" {
  description = "access ip"
  value       = openstack_compute_instance_v2.indexer.access_ip_v4
}
