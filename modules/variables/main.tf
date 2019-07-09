variable "workspace" {
  description = "Governs all the output"
}

variable stage_map {
  description = "Assign workspace names (lval) to stage names (rval). There might be more workspaces than stages!"
  type = "map"
  default = {
    spielwiese     = "spielwiese"
  }
}

output "stage" {
  value = var.stage_map[var.workspace]
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
  value = var.stage_letter_map[var.stage_map[var.workspace]]
}

variable "syslog_ip_list_map" {
  description = "List of fixed IPs for syslog instances"
  type = "map"
  default = {
    spielwiese    = ["10.104.198.150",
                     "10.104.198.182"]
  }
}

output "syslog_ip_list" {
  value = var.syslog_ip_list_map[var.stage_map[var.workspace]]
}

variable "indexer_ip_list_map" {
  description = "List of fixed IPs for indexer instances"
  type = "map"
  default = {
    spielwiese = ["10.104.198.138",
                  "10.104.198.171",
                  "10.104.198.132",
                  "10.104.198.169"]
  }
}

output "indexer_ip_list" {
  value = var.indexer_ip_list_map[var.stage_map[var.workspace]]
}
