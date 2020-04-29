# TODO: Using mod.variables in both stages and shared causes quirks because shared does not have a stage. Maybe refactor into two separate variable modules.
# - One which takes tenant/stage as input and is (exclusively) used in stages
# - Another one which takes tenant as input and is (exclusively) used in shared. Shared currently only really uses it for provider auth to get tenant name

variable "tenant_map" {
  # TODO: The workspace idea seems to confuse people, esp. because tf.workspace != tenant.name
  description = "1:1 assignment from workspace name to tenant name"
  type        = map
  default = {
    default    = "tsch_rz_t_001"
    production = "tsch_rz_p_001"
  }
}
output "tenant" {
  description = "Tenant name for current workspace"
  value       = var.tenant_map[var.workspace]
}

# Used for local state files. Obsolete when using S3 remote state
#variable "shared_statefile_map" {
#  description = "1:1 assignment from workspace name to terraform state filename"
#  type        = map
#  default = {
#    default    = "../../shared/terraform.tfstate"
#    production = "../../shared/terraform.tfstate.d/production/terraform.tfstate"
#  }
#}
#output "shared_statefile" {
#  description = "Terraform state filename for current workspace"
#  value       = var.shared_statefile_map[var.workspace]
#}

# autoselect the proper S3 remote state. Terraform does not interpolate this by workspace automatically
variable "s3_shared_config_map" {
  description = "1:1 assignment from workspace name to S3 state filename"
  type        = map
  default = {
    default    = "shared.tfstate"
    production = "env:/production/shared.tfstate"
  }
}
output "s3_shared_config" {
  description = "Connection properties for accessing S3 shared state file"
  value = {
    profile        = "sbb-splunk"
    bucket         = "sbb-splunkterraform-prod"
    region         = "eu-central-1"
    key            = var.s3_shared_config_map[var.workspace]
    dynamodb_table = "splunkterraform"
  }
}

variable "sbb_infrastructure_stage_map" {
  description = "1:1 assignment from workspace name to tenant name"
  type        = map
  default = {
    g0 = "prod"
    h0 = "prod"
    p0 = "prod"
    t0 = "test"
    w0 = "dev"
  }
}
output "sbb_infrastructure_stage" {
  description = "SBB stage definition as per https://confluence.sbb.ch/display/OTC/Tagging+Policy"
  value       = contains(keys(var.sbb_infrastructure_stage_map), var.stage) ? var.sbb_infrastructure_stage_map[var.stage] : "missing"
}


# Concept of sizing:
# Each flavor_<type>_map contains sizing for an instance type divided by tenant
# and stage. flavor_default_map is used as a default for all instance types
# which do not have specific requirements. If an instance type turns out to
# have specific requirements then an additional flavor_<type>(_map) is created.
# In such a case...
# - ... (if this instance type has additional requirements like additional disks)
#   an additional <type> module should also be created which then uses this.
#   For an example see modules/sh/main.tf
# - ... (if this instance type has no additional requirements)
#   no module should be created but the flavor should be passed to genericecs
#   from <stage>/main.tf
# --- List of supported OTC flavors
#$ openstack --os-cloud otc-sbb-p flavor list #(some columns discarded for brevity)
#+--------------+--------+--------+
#| ID           |    RAM |  VCPUs |
#+--------------+--------+--------+
#| s2.medium.1  |   1024 |      1 |
#| s2.medium.2  |   2048 |      1 |
#| s2.medium.4  |   4096 |      1 |
#| s2.medium.8  |   8192 |      1 |
#| s2.large.1   |   2048 |      2 |
#| s2.large.2   |   4096 |      2 |
#| s2.large.4   |   8192 |      2 |
#| s2.large.8   |  16384 |      2 |
#| s2.xlarge.1  |   4096 |      4 |
#| s2.xlarge.2  |   8192 |      4 |
#| s2.xlarge.4  |  16384 |      4 |
#| s2.xlarge.8  |  32768 |      4 |
#| s2.2xlarge.1 |   8192 |      8 |
#| s2.2xlarge.2 |  16384 |      8 |
#| s2.2xlarge.4 |  32768 |      8 |
#| s2.2xlarge.8 |  65536 |      8 |
#| s2.4xlarge.1 |  16384 |     16 |
#| s2.4xlarge.2 |  32768 |     16 |
#| s2.4xlarge.4 |  65536 |     16 |
#| s2.4xlarge.8 | 131072 |     16 |
#| s2.8xlarge.1 |  32768 |     32 |
#| s2.8xlarge.2 |  65536 |     32 |
#| s2.8xlarge.4 | 131072 |     32 |
#| s2.8xlarge.8 | 262144 |     32 |
#+--------------+--------+--------+

variable "flavor_ix_map" {
  description = "Indexer VM sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      # size test (almost) like prodution, maybe better idea anyway. The full size does not (currently 2019-08) fit and leads to errors
      p0 : "s3.4xlarge.1"
      t0 : "s2.4xlarge.1"
      w0 : "s2.xlarge.2"
    }
    production = {
      p0 : "s3.4xlarge.2"
      t0 : "s3.4xlarge.1"
      w0 : "s3.4xlarge.1"
    }
  }
}
output "flavor_ix" {
  # note that this behaviour is not perfect. It returns a reasonably wrong value in case a stage does not exist. Instead terraform should abort with failure
  description = "Indexer VM size for current tenant/stage"
  value       = contains(keys(var.flavor_ix_map[var.workspace]), var.stage) ? var.flavor_ix_map[var.workspace][var.stage] : "missing"
}

variable "flavor_sh_map" {
  description = "Searchhead VM sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      p0 : "s3.4xlarge.1"
      t0 : "s2.4xlarge.1"
      w0 : "s2.xlarge.2"
    }
    production = {
      p0 : "s3.4xlarge.2"
      t0 : "s3.4xlarge.1"
      w0 : "s3.4xlarge.1"
    }
  }
}
output "flavor_sh" {
  description = "Searchhead VM size for current tenant/stage"
  value       = contains(keys(var.flavor_sh_map[var.workspace]), var.stage) ? var.flavor_sh_map[var.workspace][var.stage] : "missing"
}

variable "flavor_es_map" {
  description = "Enterprise Searchhead VM sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      p0 : "s3.4xlarge.2"
      t0 : "s2.4xlarge.2"
      w0 : "s2.xlarge.2"
    }
    production = {
      p0 : "s3.4xlarge.2"
      t0 : "s3.4xlarge.2"
      w0 : "s3.4xlarge.2"
    }
  }
}
output "flavor_es" {
  description = "Enterprise Searchhead VM size for current tenant/stage"
  value       = contains(keys(var.flavor_es_map[var.workspace]), var.stage) ? var.flavor_es_map[var.workspace][var.stage] : "missing"
}

variable "flavor_si_map" {
  description = "Single Instance Searchhead VM sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      p0 : "s3.4xlarge.2"
      t0 : "s2.4xlarge.2"
      w0 : "s2.xlarge.2"
    }
    production = {
      p0 : "s3.4xlarge.2"
      t0 : "s3.4xlarge.2"
      w0 : "s3.4xlarge.2"
    }
  }
}
output "flavor_si" {
  description = "Single Instance Searchhead VM size for current tenant/stage"
  value       = contains(keys(var.flavor_si_map[var.workspace]), var.stage) ? var.flavor_si_map[var.workspace][var.stage] : "missing"
}

variable "flavor_sy_map" {
  description = "Syslog VM size (split by tenant)"
  # Small enough so one size fits all. Can be made more granular if required (see e.g. sh or ix).
  type        = map
  default = {
    default    = "s2.large.4"
    production = "s3.large.4"
  }
}
output "flavor_sy" {
  description = "Syslog VM size for current tenant/stage"
  value       = contains(keys(var.flavor_sy_map), var.workspace) ? var.flavor_sy_map[var.workspace] : "missing"
}

variable "flavor_ds_map" {
  description = "Deployment server VM size (split by tenant)"
  # Sizing agreed with customer on workshop 2020-02-12
  type        = map
  default = {
    default    = "s2.xlarge.2"
    production = "s3.2xlarge.2"
  }
}
output "flavor_ds" {
  description = "Deployment server VM size for current tenant/stage"
  value       = contains(keys(var.flavor_ds_map), var.workspace) ? var.flavor_ds_map[var.workspace] : "missing"
}

variable "flavor_lm_map" {
  description = "License master VM size (split by tenant)"
  # Sizing agreed with customer on workshop 2020-02-12
  type        = map
  default = {
    default    = "s2.xlarge.2"
    production = "s3.xlarge.2"
  }
}
output "flavor_lm" {
  description = "License master VM size for current tenant/stage"
  value       = contains(keys(var.flavor_lm_map), var.workspace) ? var.flavor_lm_map[var.workspace] : "missing"
}

variable "flavor_default_map" {
  description = "Default VM sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      d0 : "s2.4xlarge.1"
      g0 : "s2.4xlarge.1"
      h0 : "s2.4xlarge.1"
      p0 : "s3.4xlarge.1"
      t0 : "s2.4xlarge.1"
      w0 : "s2.xlarge.2"
    }
    production = {
      d0 : "s3.4xlarge.1"
      g0 : "s3.4xlarge.1"
      h0 : "s3.4xlarge.1"
      p0 : "s3.4xlarge.1"
      t0 : "s3.4xlarge.1"
      w0 : "s3.4xlarge.1"
    }
  }
}
output "flavor_default" {
  description = "Default VM size for current tenant/stage"
  value       = contains(keys(var.flavor_default_map[var.workspace]), var.stage) ? var.flavor_default_map[var.workspace][var.stage] : "missing"
}

output "primary_dns" {
  description = "Primary DNS server"
  value       = "10.124.216.29"
}

output "secondary_dns" {
  description = "Secondary DNS server"
  value       = "10.124.217.29"
}

output "pvsize_root" {
  description = "Size of (ephemeral) root pv"
  value       = 50
}

output "pvsize_opt" {
  description = "Size of /opt pv"
  value       = 100
}

variable "pvsize_kvstore_map" {
  description = "Size of /var/splunk/kvstore pv (split by stage)"
  type        = map
  default = {
    p0 : 50
    t0 : 10
    w0 : 10
  }
}
output "pvsize_kvstore" {
  description = "Size of /var/splunk/kvstore pv"
  value       = contains(keys(var.pvsize_kvstore_map), var.stage) ? var.pvsize_kvstore_map[var.stage] : "missing"
}

variable "pvsize_var_map" {
  description = "Size of /var/x pv (split by tenant)"
  type        = map
  default = {
    default    = 20
    production = 500
  }
}
output "pvsize_var" {
  description = "Size of /var/x pv. This is only currently used for sy systems which receive a lot of data"
  value       = var.pvsize_var_map[var.workspace]
}

variable "pvsize_hot_map" {
  description = "hot bucket pv sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      d0 : 5
      p0 : 5
      t0 : 5
      w0 : 5
    }
    production = {
      d0 : 5
      p0 : 250
      t0 : 25
      w0 : 5
    }
  }
}
output "pvsize_hot" {
  description = "Size of a single splunk hot/warm bucket pv for current tenant/stage"
  value       = contains(keys(var.pvsize_hot_map[var.workspace]), var.stage) ? var.pvsize_hot_map[var.workspace][var.stage] : "missing"
}

variable "pvsize_cold_map" {
  description = "cold bucket pv sizes (split by tenant and stage)"
  type        = map
  default = {
    default = {
      d0 : 50
      p0 : 50
      t0 : 50
      w0 : 50
    }
    production = {
      d0 : 50
      p0 : 2500
      t0 : 250
      w0 : 50
    }
  }
}
output "pvsize_cold" {
  description = "Size of a single splunk cold bucket pv for current tenant/stage"
  value       = contains(keys(var.pvsize_cold_map[var.workspace]), var.stage) ? var.pvsize_cold_map[var.workspace][var.stage] : "missing"
}

variable "subnet_cidr_list_map" {
  description = "Subnet CIDRs (split by tenant)"
  type        = map
  default = {
    default = {
      netA-az1 = "10.104.198.192/28",
      netA-az2 = "10.104.198.208/28",
      # no space for buffer netB :-(
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
output "subnet_cidr_list" {
  description = "List of subnet CIDRs for current tenant"
  value       = var.subnet_cidr_list_map[var.workspace]
}

variable "gateway_list_map" {
  description = "Network gateways (split by tenant)"
  type        = map
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
output "gateway_list" {
  description = "List of network gateways for current tenant"
  value       = var.gateway_list_map[var.workspace]
}


# Poor Mans DNS
variable "pmdns_list_map" {
  description = "Assignment of system to IP"
  # For servers name nomenclature refer to http://wiki.t-systems.ch/x/ieMLAg

  default = {
    default = {
      # Test tenant > Prod subnet > netA (AZ1 network) > 10.104.198.194 - 10.104.198.206
      splp0cm000 : "10.104.198.194",
      splp0hf000 : "10.104.198.195",
      splp0ix000 : "10.104.198.196",
      splp0ix002 : "10.104.198.197",
      splp0mt000 : "10.104.198.198",
      splp0sh000 : "10.104.198.199",
      splp0sh002 : "10.104.198.200",
      splp0sy000 : "10.104.198.201",
      splg0ds000 : "10.104.198.202",
      splg0lm000 : "10.104.198.203",
      splp0si000 : "10.104.198.204",
      #--------- : "10.104.198.205", OTC System interface
      #--------- : "10.104.198.206", OTC DHCP service

      # Test tenant > Prod subnet > netA (AZ2 network) > 10.104.198.210 - 10.104.198.222
      splp0hf001 : "10.104.198.210",
      splp0ix001 : "10.104.198.211",
      splp0ix003 : "10.104.198.212",
      splp0sh001 : "10.104.198.213",
      splp0sy001 : "10.104.198.214",
      splh0sy001 : "10.104.198.215",
      splp0es001 : "10.104.198.216",
      ########## : "10.104.198.217",
      ########## : "10.104.198.218",
      ########## : "10.104.198.219",
      ########## : "10.104.198.220",
      #--------- : "10.104.198.221", OTC System interface
      #--------- : "10.104.198.222", OTC DHCP service

      # Test tenant > nonProd subnet - netC (AZ1 network) > 10.104.198.226 - 10.104.198.238
      splw0cm000 : "10.104.198.226",
      splw0hf000 : "10.104.198.227",
      splw0ix000 : "10.104.198.228",
      splw0mt000 : "10.104.198.229",
      splw0sh000 : "10.104.198.230",
      splw0sy000 : "10.104.198.231",
      splw0sh002 : "10.104.198.232",
      ########## : "10.104.198.233",
      ########## : "10.104.198.234",
      ########## : "10.104.198.235",
      splw0ix002 : "10.104.198.236",
      #--------- : "10.104.198.237", OTC System interface
      #--------- : "10.104.198.238", OTC DHCP service

      # Test tenant > nonProd subnet - netC (AZ2 network) > 10.104.198.242 - 10.104.198.254
      splw0ix001 : "10.104.198.242",
      splw0sh001 : "10.104.198.243",
      ########## : "10.104.198.244",
      splw0ix003 : "10.104.198.245",
      splw0es001 : "10.104.198.246",
      ########## : "10.104.198.247",
      ########## : "10.104.198.248",
      ########## : "10.104.198.249",
      ########## : "10.104.198.250",
      ########## : "10.104.198.251",
      ########## : "10.104.198.252",
      #--------- : "10.104.198.253", OTC System interface
      #--------- : "10.104.198.254", OTC DHCP service
    }
    production = {
      # Prod tenant > Prod subnet - netA (AZ1 network) > 10.104.146.2  - 10.104.146.62
      splp0cm000 : "10.104.146.2",
      splp0hf000 : "10.104.146.3",
      splp0ix000 : "10.104.146.4",
      splp0ix002 : "10.104.146.5",
      splp0mt000 : "10.104.146.6",
      splp0sh000 : "10.104.146.7",
      splp0sh002 : "10.104.146.8",
      splp0sy000 : "10.104.146.9",
      splh0sy000 : "10.104.146.10",
      splp0si000 : "10.104.146.11",
      splg0ds000 : "10.104.146.12",
      splg0lm000 : "10.104.146.13",
      ########## : "10.104.146.14",
      ########## : "10.104.146.15",
      ########## : "10.104.146.16",
      ########## : "10.104.146.17",
      ########## : "10.104.146.18",
      ########## : "10.104.146.19",
      ########## : "10.104.146.20",
      ########## : "10.104.146.21",
      ########## : "10.104.146.22",
      ########## : "10.104.146.23",
      ########## : "10.104.146.24",
      ########## : "10.104.146.25",
      ########## : "10.104.146.26",
      ########## : "10.104.146.27",
      ########## : "10.104.146.28",
      ########## : "10.104.146.29",
      ########## : "10.104.146.30",
      ########## : "10.104.146.31",
      ########## : "10.104.146.32",
      ########## : "10.104.146.33",
      ########## : "10.104.146.34",
      ########## : "10.104.146.35",
      #splg0bd000 : "10.104.146.36", managed manually
      ########## : "10.104.146.37",
      ########## : "10.104.146.38",
      ########## : "10.104.146.39",
      ########## : "10.104.146.40",
      #splg0bd001 : "10.104.146.41", managed manually
      ########## : "10.104.146.42",
      ########## : "10.104.146.43",
      ########## : "10.104.146.44",
      ########## : "10.104.146.45",
      ########## : "10.104.146.46",
      ########## : "10.104.146.47",
      ########## : "10.104.146.48",
      ########## : "10.104.146.49",
      ########## : "10.104.146.50",
      ########## : "10.104.146.51",
      ########## : "10.104.146.52",
      ########## : "10.104.146.53",
      ########## : "10.104.146.54",
      ########## : "10.104.146.55",
      ########## : "10.104.146.56",
      ########## : "10.104.146.57",
      ########## : "10.104.146.58",
      ########## : "10.104.146.59",
      ##########  : "10.104.146.60"
      #--------- : "10.104.146.61", OTC System interface
      #--------- : "10.104.146.62", OTC DHCP service

      # Prod tenant > Prod subnet - netA (AZ2 network) > 10.104.146.66 - 10.104.146.126
      splp0hf001 : "10.104.146.66",
      splp0ix001 : "10.104.146.67",
      splp0ix003 : "10.104.146.68",
      ########## : "10.104.146.69", # faulty vm, kept for analysis, see https://issues.sbb.ch/browse/MONITORING-1007 or SM9 IM0028676827
      splp0sy001 : "10.104.146.70",
      splh0sy001 : "10.104.146.71",
      splp0es001 : "10.104.146.72",
      splp0sh001 : "10.104.146.73",
      ########## : "10.104.146.74",
      ########## : "10.104.146.75",
      ########## : "10.104.146.76",
      ########## : "10.104.146.77",
      ########## : "10.104.146.78",
      ########## : "10.104.146.79",
      ########## : "10.104.146.80",
      ########## : "10.104.146.81",
      ########## : "10.104.146.82",
      ########## : "10.104.146.83",
      ########## : "10.104.146.84",
      ########## : "10.104.146.85",
      ########## : "10.104.146.86",
      ########## : "10.104.146.87",
      ########## : "10.104.146.88",
      ########## : "10.104.146.89",
      ########## : "10.104.146.90",
      ########## : "10.104.146.91",
      ########## : "10.104.146.92",
      ########## : "10.104.146.93",
      ########## : "10.104.146.94",
      ########## : "10.104.146.95",
      ########## : "10.104.146.96",
      ########## : "10.104.146.97",
      ########## : "10.104.146.98",
      ########## : "10.104.146.99",
      ########## : "10.104.146.100",
      ########## : "10.104.146.101",
      ########## : "10.104.146.102",
      ########## : "10.104.146.103",
      ########## : "10.104.146.104",
      ########## : "10.104.146.105",
      ########## : "10.104.146.106",
      ########## : "10.104.146.107",
      ########## : "10.104.146.108",
      ########## : "10.104.146.109",
      ########## : "10.104.146.110",
      ########## : "10.104.146.111",
      ########## : "10.104.146.112",
      ########## : "10.104.146.113",
      ########## : "10.104.146.114",
      ########## : "10.104.146.115",
      ########## : "10.104.146.116",
      ########## : "10.104.146.117",
      ########## : "10.104.146.118",
      ########## : "10.104.146.119",
      ########## : "10.104.146.120",
      ########## : "10.104.146.121",
      ########## : "10.104.146.122",
      ########## : "10.104.146.123",
      ########## : "10.104.146.124",
      #--------- : "10.104.146.125", OTC System interface
      #--------- : "10.104.146.126", OTC DHCP service

      # Prod tenant > spare buffer subnet - netB (AZ1 network) > 10.104.146.130 - 10.104.146.158
      ######### : <IPs not assignable yet, they're reserved until all previous actual IPs are used>

      # Prod tenant > spare buffer subnet - netB (AZ2 network) > 10.104.146.162 - 10.104.146.190
      ######### : <IPs not assignable yet, they're reserved until all previous actual IPs are used>

      # Prod tenant > nonProd subnet - netC (AZ1 network) > 10.104.146.194 - 10.104.146.223
      splw0cm000 : "10.104.146.194",
      splw0hf000 : "10.104.146.195",
      splw0ix000 : "10.104.146.196",
      splw0mt000 : "10.104.146.197",
      splw0sh000 : "10.104.146.198",
      splw0sy000 : "10.104.146.199",
      splt0sh000 : "10.104.146.200",
      splt0ix000 : "10.104.146.201",
      splt0sy000 : "10.104.146.202",
      splt0mt000 : "10.104.146.203",
      ########## : "10.104.146.204",
      splt0cm000 : "10.104.146.205",
      ########## : "10.104.146.206",
      splt0hf000 : "10.104.146.207",
      splt0sh002 : "10.104.146.208",
      ########## : "10.104.146.209",
      splw0sh002 : "10.104.146.210",
      splw0ix002 : "10.104.146.211",
      splt0ix002 : "10.104.146.212",
      ########## : "10.104.146.213",
      ########## : "10.104.146.214",
      ########## : "10.104.146.215",
      ########## : "10.104.146.216",
      ########## : "10.104.146.217",
      ########## : "10.104.146.218",
      ########## : "10.104.146.219",
      ########## : "10.104.146.220",
      ########## : "10.104.146.221",
      #--------- : "10.104.146.222", OTC System interface
      #--------- : "10.104.146.223", OTC DHCP service

      # Prod tenant > nonProd subnet - netC (AZ2 network) > 10.104.146.226 - 10.104.146.254
      splw0ix001 : "10.104.146.226",
      splw0sh001 : "10.104.146.227",
      splw0ix003 : "10.104.146.228",
      splt0sh001 : "10.104.146.229",
      splt0ix001 : "10.104.146.230",
      splt0ix003 : "10.104.146.231",
      ########## : "10.104.146.232",
      splw0es001 : "10.104.146.233",
      splt0es001 : "10.104.146.234",
      ########## : "10.104.146.235",
      ########## : "10.104.146.236",
      ########## : "10.104.146.237",
      ########## : "10.104.146.238",
      ########## : "10.104.146.239",
      ########## : "10.104.146.240",
      ########## : "10.104.146.241",
      ########## : "10.104.146.242",
      ########## : "10.104.146.243",
      ########## : "10.104.146.244",
      ########## : "10.104.146.245",
      ########## : "10.104.146.246",
      ########## : "10.104.146.247",
      ########## : "10.104.146.248",
      ########## : "10.104.146.249",
      ########## : "10.104.146.250",
      ########## : "10.104.146.251",
      ########## : "10.104.146.252",
      #--------- : "10.104.146.253", OTC System interface
      #--------- : "10.104.146.254", OTC DHCP service
    }
  }
}
output "pmdns_list" {
  description = "List of (name:ip) tuples for current tenant"
  value       = var.pmdns_list_map[var.workspace]
}
