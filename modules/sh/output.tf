output "id" {
  description = "vm id"
  value       = module.sh-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.sh-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.sh-instance.name
}

output "az" {
  description = "instance name"
  value       = module.sh-instance.az
}
