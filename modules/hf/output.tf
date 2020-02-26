output "id" {
  description = "vm id"
  value       = module.hf-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.hf-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.hf-instance.name
}

output "az" {
  description = "instance name"
  value       = module.hf-instance.az
}
