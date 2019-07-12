variable "workspace" {
  description = "Governs all the output"
}

variable stage_map {
  description = "Assign workspace names (lval) to stage names (rval). There might be more workspaces than stages!"
  type = "map"
  default = {
    spielwiese     = "spielwiese"
    spielwiese-p   = "spielwiese-p"
  }
}

output "stage" {
  value = var.stage_map[var.workspace]
}

variable "stage_letter_map" {
  description = "Each stage must be represented by a single letter"
  type = "map"
  default = {
    spielwiese   = "S"
    spielwiese-p = "S"
    production   = "P"
    development  = "D"
    test         = "T"
    integration  = "I"
  }
}

output "stage_letter" {
  value = var.stage_letter_map[var.stage_map[var.workspace]]
}

variable "searchhead_ip_list_map" {
  description = "List of fixed IPs for searchhead instances"
  type = "map"
  default = {
    spielwiese   = []
    # if using own networks
    #spielwiese   = ["10.0.1.20",
    #                "10.0.2.20"]
    spielwiese-p = ["10.104.146.225",
                    "10.104.146.241"]
  }
}

output "searchhead_ip_list" {
  value = var.searchhead_ip_list_map[var.stage_map[var.workspace]]
}

variable "indexer_ip_list_map" {
  description = "List of fixed IPs for indexer instances"
  type = "map"
  default = {
    spielwiese   = ["10.104.198.138",
                    "10.104.198.171"]
    # if using own networks
    #spielwiese   = ["10.0.1.10",
    #                "10.0.2.10"]
    spielwiese-p = ["10.104.146.226",
                    "10.104.146.242"]
  }
}

output "indexer_ip_list" {
  value = var.indexer_ip_list_map[var.stage_map[var.workspace]]
}

variable "syslog_ip_list_map" {
  description = "List of fixed IPs for syslog instances"
  type = "map"
  default = {
    # if using real IPs
    spielwiese    = ["10.104.198.150",
                     "10.104.198.182"]
    # if using own networks
    #spielwiese    = ["10.0.1.30",
    #                 "10.0.2.30"]
    spielwiese-p  = ["10.104.146.227",
                     "10.104.146.243"]
  }
}

output "syslog_ip_list" {
  value = var.syslog_ip_list_map[var.stage_map[var.workspace]]
}
