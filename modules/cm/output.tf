output "id" {
  description = "vm id"
  value       = module.cm-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.cm-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.cm-instance.name
}

output "az" {
  description = "instance name"
  value       = module.cm-instance.az
}
