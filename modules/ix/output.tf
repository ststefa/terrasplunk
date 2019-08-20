output "id" {
  description = "vm id"
  value       = module.ix-instance.id
}

output "ip" {
  description = "access ip"
  value       = module.ix-instance.ip
}

output "name" {
  description = "instance name"
  value       = module.ix-instance.name
}

output "az" {
  description = "instance name"
  value       = module.ix-instance.az
}
