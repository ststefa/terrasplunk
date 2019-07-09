variable "stage" {
  description = "dev / apptest / ..."
}

variable "stage_letter_map" {
  description = "Each stage must be represented by a single letter"
  type = "map"
  default = {
    spielwiese  = "S"
    production  = "P"
    development = "D"
    test        = "T"
    integration = "I"
  }
}

output "stage_letter" {
  value = var.stage_letter_map[var.stage]
}

variable "syslog_ip_list_map" {
  description = "Each stage must be represented by a single letter"
  type = "map"
  default = {
    spielwiese    = ["10.104.198.150",
                     "10.104.198.182"]
  }
}

output "syslog_ip_list" {
  value = var.syslog_ip_list_map[var.stage]
}
