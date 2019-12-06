output "id" {
  description = "vm id"
  value       = module.es-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.es-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.es-instance.name
}

output "az" {
  description = "instance name"
  value       = module.es-instance.az
}
