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
  #$ openstack --os-cloud otc-sbb-t flavor list
  #+--------------+--------------+--------+------+-----------+-------+-----------+
  #| ID           | Name         |    RAM | Disk | Ephemeral | VCPUs | Is Public |
  #+--------------+--------------+--------+------+-----------+-------+-----------+
  #| s2.2xlarge.1 | s2.2xlarge.1 |   8192 |    0 |         0 |     8 | True      |
  #| s2.2xlarge.2 | s2.2xlarge.2 |  16384 |    0 |         0 |     8 | True      |
  #| s2.2xlarge.4 | s2.2xlarge.4 |  32768 |    0 |         0 |     8 | True      |
  #| s2.2xlarge.8 | s2.2xlarge.8 |  65536 |    0 |         0 |     8 | True      |
  #| s2.4xlarge.1 | s2.4xlarge.1 |  16384 |    0 |         0 |    16 | True      |
  #| s2.4xlarge.2 | s2.4xlarge.2 |  32768 |    0 |         0 |    16 | True      |
  #| s2.4xlarge.4 | s2.4xlarge.4 |  65536 |    0 |         0 |    16 | True      |
  #| s2.4xlarge.8 | s2.4xlarge.8 | 131072 |    0 |         0 |    16 | True      |
  #| s2.8xlarge.1 | s2.8xlarge.1 |  32768 |    0 |         0 |    32 | True      |
  #| s2.8xlarge.2 | s2.8xlarge.2 |  65536 |    0 |         0 |    32 | True      |
  #| s2.8xlarge.4 | s2.8xlarge.4 | 131072 |    0 |         0 |    32 | True      |
  #| s2.8xlarge.8 | s2.8xlarge.8 | 262144 |    0 |         0 |    32 | True      |
  #| s2.large.1   | s2.large.1   |   2048 |    0 |         0 |     2 | True      |
  #| s2.large.2   | s2.large.2   |   4096 |    0 |         0 |     2 | True      |
  #| s2.large.4   | s2.large.4   |   8192 |    0 |         0 |     2 | True      |
  #| s2.large.8   | s2.large.8   |  16384 |    0 |         0 |     2 | True      |
  #| s2.medium.1  | s2.medium.1  |   1024 |    0 |         0 |     1 | True      |
  #| s2.medium.2  | s2.medium.2  |   2048 |    0 |         0 |     1 | True      |
  #| s2.medium.4  | s2.medium.4  |   4096 |    0 |         0 |     1 | True      |
  #| s2.medium.8  | s2.medium.8  |   8192 |    0 |         0 |     1 | True      |
  #| s2.xlarge.1  | s2.xlarge.1  |   4096 |    0 |         0 |     4 | True      |
  #| s2.xlarge.2  | s2.xlarge.2  |   8192 |    0 |         0 |     4 | True      |
  #| s2.xlarge.4  | s2.xlarge.4  |  16384 |    0 |         0 |     4 | True      |
  #| s2.xlarge.8  | s2.xlarge.8  |  32768 |    0 |         0 |     4 | True      |
  #+--------------+--------------+--------+------+-----------+-------+-----------+

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
      #dontcare: ""
    }
    production = {
      development : "s2.medium.4"
      test : "s2.xlarge.4"
      quality : "s2.xlarge.4"
      production : "s2.2xlarge.4"
      spielwiese : "s2.medium.4"
      universal : "s2.medium.4"
      #dontcare: ""
    }
  }
}
output "flavor" {
  # note that this behaviour is not perfect. It returns a reasonably wrong value in case a stage does not exist. Instead terraform should really abort with failure
  value = contains(keys(var.flavor_map[var.workspace]), var.stage) ? var.flavor_map[var.workspace][var.stage] : ""
}

output "pvsize_root" {
  value = 20
}

output "pvsize_opt" {
  value = 20
}

variable "pvsize_hot_map" {
  description = "Size of Hot-warm Splunk buckets phisical volume (pv)"
  type        = "map"
  default = {
    default = {
      development : 50
      test : 50
      quality : 50
      production : 50
      spielwiese : 50
      universal : 50
    }
    production = {
      development : 50
      test : 50
      quality : 50
      production : 100
      spielwiese : 50
      universal : 50
    }
  }
}
output "pvsize_hot" {
  value = contains(keys(var.pvsize_hot_map[var.workspace]), var.stage) ? var.pvsize_hot_map[var.workspace][var.stage] : ""
}

variable "pvsize_cold_map" {
  description = "Size of Cold Splunk buckets phisical volume (pv)"
  type        = "map"
  default = {
    default = {
      development : 50
      test : 50
      quality : 50
      production : 50
      spielwiese : 50
      universal : 50
    }
    production = {
      development : 50
      test : 50
      quality : 50
      production : 100
      spielwiese : 50
      universal : 50
    }
  }
}
output "pvsize_cold" {
  value = contains(keys(var.pvsize_cold_map[var.workspace]), var.stage) ? var.pvsize_cold_map[var.workspace][var.stage] : ""
}

variable "subnet_cidr_map" {
  description = "Subnet CIDRs"
  type        = "map"
  default = {
    default = {
      netA-az1 = "10.104.198.192/28",
      netA-az2 = "10.104.198.208/28",
      # no space for buffer :-(
      netC-az1 = "10.104.198.224/28",
      netC-az2 = "10.104.198.240/28",
    }
    production = {
      netA-az1 = "10.104.146.0/26",
      netA-az2 = "10.104.146.64/26",
      netB-az1 = "10.104.146.128/27",
      netB-az2 = "10.104.146.160/27",
      netC-az1 = "10.104.146.192/27",
      netC-az2 = "10.104.146.224/27",
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
      netA-az1 = "10.104.198.193",
      netA-az2 = "10.104.198.209",
      # no space for buffer :-(
      netC-az1 = "10.104.198.225",
      netC-az2 = "10.104.198.241",
    }
    production = {
      netA-az1 = "10.104.146.1",
      netA-az2 = "10.104.146.65",
      netB-az1 = "10.104.146.129",
      netB-az2 = "10.104.146.161",
      netC-az1 = "10.104.146.193",
      netC-az2 = "10.104.146.225",
    }
  }
}
output "gateway" {
  value = var.gateway_map[var.workspace]
}


# poor mans DNS
variable "pmdns_map" {
  description = "Where others use rocket science we do it by hand"
  # For servers name nomenclature refert to http://wiki.t-systems.ch/x/ieMLAg

  default = {
    default = {
      # Test tenant > Prod subnet > netA (AZ1 network) > 10.104.198.194 - 10.104.198.206
      splp0cm00 : "10.104.198.194",
      splp0hf00 : "10.104.198.195",
      splp0id00 : "10.104.198.196",
      splp0id02 : "10.104.198.197",
      splp0mt00 : "10.104.198.198",
      splp0sh00 : "10.104.198.199",
      splp0sh02 : "10.104.198.200",
      splp0sy00 : "10.104.198.201",
      ######### : "10.104.198.202",
      ######### : "10.104.198.203",
      ######### : "10.104.198.204",
      ######### : "10.104.198.205",
      ######### : "10.104.198.206",

      # Test tenant > Prod subnet > netA (AZ2 network) > 10.104.198.210 - 10.104.198.222
      splp0hf01 : "10.104.198.210",
      splp0id01 : "10.104.198.211",
      splp0id03 : "10.104.198.212",
      splp0sh01 : "10.104.198.213",
      splp0sy01 : "10.104.198.214",
      ######### : "10.104.198.215",
      ######### : "10.104.198.216",
      ######### : "10.104.198.217",
      ######### : "10.104.198.218",
      ######### : "10.104.198.219",
      ######### : "10.104.198.220",
      ######### : "10.104.198.221",
      ######### : "10.104.198.222",

      # Test tenant > nonProd subnet - netC (AZ1 network) > 10.104.198.226 - 10.104.198.238
      splw0cm00 : "10.104.198.226",
      splw0hf00 : "10.104.198.227",
      splw0id00 : "10.104.198.228",
      splw0mt00 : "10.104.198.229",
      splw0sh00 : "10.104.198.230",
      splw0sy00 : "10.104.198.231",
      ######### : "10.104.198.232",
      ######### : "10.104.198.233",
      ######### : "10.104.198.234",
      ######### : "10.104.198.235",
      ######### : "10.104.198.236",
      ######### : "10.104.198.237",
      ######### : "10.104.198.238",

      # Test tenant > nonProd subnet - netC (AZ2 network) > 10.104.198.242 - 10.104.198.254
      splw0id01 : "10.104.198.242",
      splw0sh01 : "10.104.198.243",
      splw0sy01 : "10.104.198.244",
      ######### : "10.104.198.245",
      ######### : "10.104.198.246",
      ######### : "10.104.198.247",
      ######### : "10.104.198.248",
      ######### : "10.104.198.249",
      ######### : "10.104.198.250",
      ######### : "10.104.198.251",
      ######### : "10.104.198.252",
      ######### : "10.104.198.253",
      ######### : "10.104.198.254",
    }
    production = {
      # Prod tenant > Prod subnet - netA (AZ1 network) > 10.104.146.2  - 10.104.146.62
      splp0cm00 : "10.104.146.2",
      splp0hf00 : "10.104.146.3",
      splp0id00 : "10.104.146.4",
      splp0id02 : "10.104.146.5",
      splp0mt00 : "10.104.146.6",
      splp0sh00 : "10.104.146.7",
      splp0sh02 : "10.104.146.8",
      splp0sy00 : "10.104.146.9",
      ######### : "10.104.146.10",
      ######### : "10.104.146.11",
      ######### : "10.104.146.12",
      ######### : "10.104.146.13",
      ######### : "10.104.146.14",
      ######### : "10.104.146.15",
      ######### : "10.104.146.16",
      ######### : "10.104.146.17",
      ######### : "10.104.146.18",
      ######### : "10.104.146.19",
      ######### : "10.104.146.20",
      ######### : "10.104.146.21",
      ######### : "10.104.146.22",
      ######### : "10.104.146.23",
      ######### : "10.104.146.24",
      ######### : "10.104.146.25",
      ######### : "10.104.146.26",
      ######### : "10.104.146.27",
      ######### : "10.104.146.28",
      ######### : "10.104.146.29",
      ######### : "10.104.146.30",
      ######### : "10.104.146.31",
      ######### : "10.104.146.32",
      ######### : "10.104.146.33",
      ######### : "10.104.146.34",
      ######### : "10.104.146.35",
      ######### : "10.104.146.36",
      ######### : "10.104.146.37",
      ######### : "10.104.146.38",
      ######### : "10.104.146.39",
      ######### : "10.104.146.40",
      ######### : "10.104.146.41",
      ######### : "10.104.146.42",
      ######### : "10.104.146.43",
      ######### : "10.104.146.44",
      ######### : "10.104.146.45",
      ######### : "10.104.146.46",
      ######### : "10.104.146.47",
      ######### : "10.104.146.48",
      ######### : "10.104.146.49",
      ######### : "10.104.146.50",
      ######### : "10.104.146.51",
      ######### : "10.104.146.52",
      ######### : "10.104.146.53",
      ######### : "10.104.146.54",
      ######### : "10.104.146.55",
      ######### : "10.104.146.56",
      ######### : "10.104.146.57",
      ######### : "10.104.146.58",
      ######### : "10.104.146.59",
      ######### : "10.104.146.60",
      ######### : "10.104.146.61",
      ######### : "10.104.146.62",
      ######### : "10.104.146.63",
      ######### : "10.104.146.64",
      ######### : "10.104.146.65",

      # Prod tenant > Prod subnet - netA (AZ2 network) > 10.104.146.66 - 10.104.146.126
      splp0hf01 : "10.104.146.66",
      splp0id01 : "10.104.146.67",
      splp0id03 : "10.104.146.68",
      splp0sh01 : "10.104.146.69",
      splp0sy01 : "10.104.146.70",
      ######### : "10.104.146.71",
      ######### : "10.104.146.72",
      ######### : "10.104.146.73",
      ######### : "10.104.146.74",
      ######### : "10.104.146.75",
      ######### : "10.104.146.76",
      ######### : "10.104.146.77",
      ######### : "10.104.146.78",
      ######### : "10.104.146.79",
      ######### : "10.104.146.80",
      ######### : "10.104.146.81",
      ######### : "10.104.146.82",
      ######### : "10.104.146.83",
      ######### : "10.104.146.84",
      ######### : "10.104.146.85",
      ######### : "10.104.146.86",
      ######### : "10.104.146.87",
      ######### : "10.104.146.88",
      ######### : "10.104.146.89",
      ######### : "10.104.146.90",
      ######### : "10.104.146.91",
      ######### : "10.104.146.92",
      ######### : "10.104.146.93",
      ######### : "10.104.146.94",
      ######### : "10.104.146.95",
      ######### : "10.104.146.96",
      ######### : "10.104.146.97",
      ######### : "10.104.146.98",
      ######### : "10.104.146.99",
      ######### : "10.104.146.100",
      ######### : "10.104.146.101",
      ######### : "10.104.146.102",
      ######### : "10.104.146.103",
      ######### : "10.104.146.104",
      ######### : "10.104.146.105",
      ######### : "10.104.146.106",
      ######### : "10.104.146.107",
      ######### : "10.104.146.108",
      ######### : "10.104.146.109",
      ######### : "10.104.146.110",
      ######### : "10.104.146.111",
      ######### : "10.104.146.112",
      ######### : "10.104.146.113",
      ######### : "10.104.146.114",
      ######### : "10.104.146.115",
      ######### : "10.104.146.116",
      ######### : "10.104.146.117",
      ######### : "10.104.146.118",
      ######### : "10.104.146.119",
      ######### : "10.104.146.120",
      ######### : "10.104.146.121",
      ######### : "10.104.146.122",
      ######### : "10.104.146.123",
      ######### : "10.104.146.124",
      ######### : "10.104.146.125",
      ######### : "10.104.146.126",

      # Prod tenant > spare buffer subnet - netB (AZ1 network) > 10.104.146.130 - 10.104.146.158
      ######### : <IPs not assignable yet, they're reserved until all previous actual IPs are used>

      # Prod tenant > spare buffer subnet - netB (AZ2 network) > 10.104.146.162 - 10.104.146.190
      ######### : <IPs not assignable yet, they're reserved until all previous actual IPs are used>

      # Prod tenant > nonProd subnet - netC (AZ1 network) > 10.104.146.194 - 10.104.146.223
      splw0cm00 : "10.104.146.194",
      splw0hf00 : "10.104.146.195",
      splw0id00 : "10.104.146.196",
      splw0mt00 : "10.104.146.197",
      splw0sh00 : "10.104.146.198",
      splw0sy00 : "10.104.146.199",
      ######### : "10.104.146.200",
      ######### : "10.104.146.201",
      ######### : "10.104.146.202",
      ######### : "10.104.146.203",
      ######### : "10.104.146.204",
      ######### : "10.104.146.205",
      ######### : "10.104.146.206",
      ######### : "10.104.146.207",
      ######### : "10.104.146.208",
      ######### : "10.104.146.209",
      ######### : "10.104.146.210",
      ######### : "10.104.146.211",
      ######### : "10.104.146.212",
      ######### : "10.104.146.213",
      ######### : "10.104.146.214",
      ######### : "10.104.146.215",
      ######### : "10.104.146.216",
      ######### : "10.104.146.217",
      ######### : "10.104.146.218",
      ######### : "10.104.146.219",
      ######### : "10.104.146.220",
      ######### : "10.104.146.221",
      ######### : "10.104.146.222",
      ######### : "10.104.146.223",

      # Prod tenant > nonProd subnet - netC (AZ2 network) > 10.104.146.226 - 10.104.146.254
      splw0id01 : "10.104.146.226",
      splw0sh01 : "10.104.146.227",
      splw0sy01 : "10.104.146.228",
      ######### : "10.104.146.229",
      ######### : "10.104.146.230",
      ######### : "10.104.146.231",
      ######### : "10.104.146.232",
      ######### : "10.104.146.233",
      ######### : "10.104.146.234",
      ######### : "10.104.146.235",
      ######### : "10.104.146.236",
      ######### : "10.104.146.237",
      ######### : "10.104.146.238",
      ######### : "10.104.146.239",
      ######### : "10.104.146.240",
      ######### : "10.104.146.241",
      ######### : "10.104.146.242",
      ######### : "10.104.146.243",
      ######### : "10.104.146.244",
      ######### : "10.104.146.245",
      ######### : "10.104.146.246",
      ######### : "10.104.146.247",
      ######### : "10.104.146.248",
      ######### : "10.104.146.249",
      ######### : "10.104.146.250",
      ######### : "10.104.146.251",
      ######### : "10.104.146.252",
      ######### : "10.104.146.253",
      ######### : "10.104.146.254",
    }
  }
}
output "pmdns" {
  value = var.pmdns_map[var.workspace]
}
