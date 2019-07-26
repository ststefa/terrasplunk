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
#  value = var.stage_letter_map[var.stage]
#}

variable "tenant_map" {
  description = "Each stage must be represented by a single letter"
  type        = "map"
  default = {
    default    = "tsch_rz_t_001"
    production = "tsch_rz_p_001"
  }
}
output "tenant" {
  value = var.tenant_map[var.workspace]
}

variable "shared_statefile_map" {
  description = "Each stage must be represented by a single letter"
  type        = "map"
  default = {
    default    = "../../shared/terraform.tfstate"
    production = "../../shared/terraform.tfstate.d/production/terraform.tfstate"
  }
}
output "shared_statefile" {
  value = var.shared_statefile_map[var.workspace]
}

variable "flavor_map" {
  description = "VM sizes to use"
  type        = "map"
  default = {
    default = {
      development : "s2.medium.4"
      test : "s2.medium.4"
      quality : "s2.medium.4"
      production : "s2.medium.8"
      spielwiese : "s2.medium.4"
      universal : "s2.medium.4"
    }
    production = {
      development : "s2.medium.4"
      test : "s2.xlarge.4"
      quality : "s2.xlarge.4"
      production : "s2.2xlarge.4"
      spielwiese : "s2.medium.4"
      universal : "s2.medium.4"
    }
  }
}
output "flavor" {
  value = var.flavor_map[var.workspace][var.stage]
}

output "pvsize_root" {
  value = 20
}

output "pvsize_opt" {
  value = 20
}

output "pvsize_hot" {
  value = 5
}

output "pvsize_cold" {
  value = 10
}

variable "subnet_cidr_map" {
  description = "Subnet CIDRs"
  type        = "map"
  default = {
    default = {
      neta-az1 = "10.104.198.192/28",
      neta-az2 = "10.104.198.208/28",
      # no space for buffer :-(
      netc-az1 = "10.104.198.224/28",
      netc-az2 = "10.104.198.240/28",
    }
    production = {
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
      # no space for buffer :-(
      netc-az1 = "10.104.198.225",
      netc-az2 = "10.104.198.241",
    }
    production = {
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
      # test tenant
      #     prod subnet
      #         10.104.198.194 - 10.104.198.206
      #         10.104.198.210 - 10.104.198.222
      #     nonprod subnet
      #         10.104.198.226 - 10.104.198.238
      #         10.104.198.242 - 10.104.198.254
      splp0cm00 : "10.104.198.194",
      splp0hf00 : "10.104.198.195",
      splp0hf01 : "10.104.198.210",
      splp0id00 : "10.104.198.196",
      splp0id01 : "10.104.198.211",
      splp0id02 : "10.104.198.197",
      splp0id03 : "10.104.198.212",
      splp0mt00 : "10.104.198.198",
      splp0sh00 : "10.104.198.199",
      splp0sh01 : "10.104.198.213",
      splp0sh02 : "10.104.198.200",
      splp0sy00 : "10.104.198.201",
      splp0sy01 : "10.104.198.214",

      splw0cm00 : "10.104.198.226",
      splw0hf00 : "10.104.198.227",
      splw0id00 : "10.104.198.228",
      splw0id01 : "10.104.198.242",
      splw0mt00 : "10.104.198.229",
      splw0sh00 : "10.104.198.230",
      splw0sh01 : "10.104.198.243",
      splw0sy00 : "10.104.198.231",
      splw0sy01 : "10.104.198.244",

    }
    production = {
      # prod tenant
      #     prod subnet
      #         usable 10.104.146.2  - 10.104.146.62
      #         usable 10.104.146.66 - 10.104.146.126
      #     spare buffer subnet
      #         10.104.146.130 - 10.104.146.158
      #         10.104.146.162 - 10.104.146.190
      #     nonprod subnet
      #         10.104.146.194 - 10.104.146.223
      #         10.104.146.226 - 10.104.146.254
      splp0cm00 : "10.104.146.2",
      splp0hf00 : "10.104.146.3",
      splp0hf01 : "10.104.146.66",
      splp0id00 : "10.104.146.4",
      splp0id01 : "10.104.146.67",
      splp0id02 : "10.104.146.5",
      splp0id03 : "10.104.146.68",
      splp0mt00 : "10.104.146.6",
      splp0sh00 : "10.104.146.7",
      splp0sh01 : "10.104.146.69",
      splp0sh02 : "10.104.146.8",
      splp0sy00 : "10.104.146.9",
      splp0sy01 : "10.104.146.70",

      splw0cm00 : "10.104.146.194",
      splw0hf00 : "10.104.146.195",
      splw0id00 : "10.104.146.196",
      splw0id01 : "10.104.146.226",
      splw0mt00 : "10.104.146.197",
      splw0sh00 : "10.104.146.198",
      splw0sh01 : "10.104.146.227",
      splw0sy00 : "10.104.146.199",
      splw0sy01 : "10.104.146.228",
    }
  }
}
output "pmdns" {
  value = var.pmdns_map[var.workspace]
}
