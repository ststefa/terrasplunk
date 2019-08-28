output "id" {
  description = "vm id"
  value       = module.mt-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.mt-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.mt-instance.name
}

output "az" {
  description = "instance name"
  value       = module.mt-instance.az
}
