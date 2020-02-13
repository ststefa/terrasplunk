output "id" {
  description = "vm id"
  value       = module.ds-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.ds-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.ds-instance.name
}

output "az" {
  description = "instance name"
  value       = module.ds-instance.az
}
