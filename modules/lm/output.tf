output "id" {
  description = "vm id"
  value       = module.lm-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.lm-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.lm-instance.name
}

output "az" {
  description = "instance name"
  value       = module.lm-instance.az
}
