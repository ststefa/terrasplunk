#variable stage_map {
#  description = "Assign workspace names (lval) to stage names (rval). There might be more workspaces than stages!"
#  type = "map"
#  default = {
#    spielwiese     = "spielwiese"
#  }
#}

#variable "stage_letter_map" {
#  description = "Each stage must be represented by a single letter"
#  type = "map"
#  default = {
#    spielwiese   = "w"
#    production   = "p"
#    development  = "d"
#    test         = "t"
#    qa           = "q"
#  }
#}
#output "stage_letter" {
#  value = var.stage_letter_map
#}

variable "tenant_map" {
  description = "Each stage must be represented by a single letter"
  type        = "map"
  default = {
    default = "tsch_rz_t_001"
    prod    = "tsch_rz_p_001"
  }
}
output "tenant" {
  value = var.tenant_map[var.workspace]
}

variable "subnet_cidr_map" {
  description = "Subnet CIDRs"
  type        = "map"
  default = {
    default = {
      neta-az1 = "10.104.198.192/28",
      neta-az2 = "10.104.198.208/28",
      # no space for buffer
      netc-az1 = "10.104.198.224/28",
      netc-az2 = "10.104.198.240/28",
    }
    prod = {
      neta-az1 = "10.104.146.0/26",
      neta-az2 = "10.104.146.64/26",
      netb-az1 = "10.104.146.128/27",
      netb-az2 = "10.104.146.160/27",
      netc-az1 = "10.104.146.192/27",
      netc-az2 = "10.104.146.224/27",
    }
  }
}
output "subnet_cidr" {
  value = var.subnet_cidr_map[var.workspace]
}

variable "gateway_map" {
  description = "List of fixed IPs for searchhead instances"
  type        = "map"
  default = {
    default = {
      neta-az1 = "10.104.198.193",
      neta-az2 = "10.104.198.209",
      # no space for buffer
      netc-az1 = "10.104.198.225",
      netc-az2 = "10.104.198.241",
    }
    prod = {
      neta-az1 = "10.104.146.1",
      neta-az2 = "10.104.146.65",
      netb-az1 = "10.104.146.129",
      netb-az2 = "10.104.146.161",
      netc-az1 = "10.104.146.193",
      netc-az2 = "10.104.146.225",
    }
  }
}
output "gateway" {
  value = var.gateway_map[var.workspace]
}


# poor mans DNS
variable "pmdns_map" {
  description = "Where others use rocket science we do it by hand"
  #sh:   Searchhead
  #it:   ITSI searchhead
  #es:   ES searchhead
  #ix:   Indexer
  #cm:   Cluster-Master
  #hf:   Heavy-Forwarder  <- Not yet implemented
  #st:   Stand-alone
  #sy:   Syslog  <- Not yet implemented
  #he:   HEC-Gateway  <- Not yet implemented
  #pr:   Parser (Syslog, HEC-Gateway and Heavy-Forwarder on same machine)
  #lm:   License-Master  <- Not yet implemented
  #dp:   Deployer  <- Not yet implemented
  #ds:   Deployment-Server  <- Not yet implemented
  #mt:   Management tools (License-Master, Deployment-Server and Deployer)
  #mc:   Monitor Console
  #bd:   Builder, where all Ansible, Terraform, etc. scripts are running  type = "map"
  default = {
    default = {
      splp0cm01 : "10.104.198.226",
      splp0hf01 : "10.104.198.227",
      splp0hf02 : "10.104.198.228",
      splp0id01 : "10.104.198.229",
      splp0id02 : "10.104.198.230",
      splp0id03 : "10.104.198.231",
      splp0id04 : "10.104.198.232",
      splp0mt01 : "10.104.198.233",
      splp0sh01 : "10.104.198.234",
      splp0sh02 : "10.104.198.235",
      splp0sh03 : "10.104.198.236",
      splp0sy01 : "10.104.198.237",
      splp0sy02 : "10.104.198.238",

    }
    prod = {
      splp0cm01 : "10.104.146.194",
      splp0hf01 : "10.104.146.195",
      splp0hf02 : "10.104.146.196",
      splp0id01 : "10.104.146.197",
      splp0id02 : "10.104.146.198",
      splp0id03 : "10.104.146.199",
      splp0id04 : "10.104.146.200",
      splp0mt01 : "10.104.146.201",
      splp0sh01 : "10.104.146.202",
      splp0sh02 : "10.104.146.203",
      splp0sh03 : "10.104.146.204",
      splp0sy01 : "10.104.146.205",
      splp0sy02 : "10.104.146.206",
    }
  }
}
output "pmdns" {
  value = var.pmdns_map[var.workspace]
}


#variable "searchhead_ip_list_map" {
#  description = "List of fixed IPs for searchhead instances"
#  type = "map"
#  default = {
#    default = {
#      spielwiese = [
#        "10.104.198.137",
#        "10.104.198.170"]
#    }
#    prod = {
#      spielwiese = [
#        "10.104.146.226",
#        "10.104.146.242"]
#    }
#  }
#}
#output "searchhead_ip_list" {
#  value = var.searchhead_ip_list_map[var.workspace][var.stage]
#}
#
#variable "indexer_ip_list_map" {
#  description = "List of fixed IPs for indexer instances"
#  type = "map"
#  default = {
#    default = {
#      spielwiese = [
#        "10.104.198.138",
#        "10.104.198.171"]
#    }
#    prod = {
#      spielwiese = [
#        "10.104.146.227",
#        "10.104.146.243"]
#    }
#  }
#}
#output "indexer_ip_list" {
#  value = var.indexer_ip_list_map[var.workspace][var.stage]
#}
#
#variable "syslog_ip_list_map" {
#  description = "List of fixed IPs for syslog instances"
#  type = "map"
#  default = {
#    default = {
#      spielwiese = [
#        "10.104.198.150",
#        "10.104.198.182"]
#    }
#    prod = {
#      spielwiese = [
#        "10.104.146.228",
#        "10.104.146.244"]
#    }
#  }
#}
#output "syslog_ip_list" {
#  value = var.syslog_ip_list_map[var.workspace][var.stage]
#}
