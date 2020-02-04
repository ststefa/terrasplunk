output "id" {
  description = "vm id"
  value       = module.si-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.si-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.si-instance.name
}

output "az" {
  description = "instance name"
  value       = module.si-instance.az
}
