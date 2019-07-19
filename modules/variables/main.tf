variable "workspace" {
  description = "One of 'default' or 'prod'"
}

variable "stage" {
  description = "One of 'spielwiese', 'dev', 'test', 'int',  or 'prod'"
}

#variable stage_map {
#  description = "Assign workspace names (lval) to stage names (rval). There might be more workspaces than stages!"
#  type = "map"
#  default = {
#    spielwiese     = "spielwiese"
#  }
#}

variable "stage_letter_map" {
  description = "Each stage must be represented by a single letter"
  type = "map"
  default = {
    spielwiese   = "s"
    production   = "p"
    development  = "d"
    test         = "t"
    integration  = "i"
  }
}
output "stage_letter" {
  value = var.stage_letter_map[var.stage]
}

variable "subnet_cidr_map" {
  description = "List of fixed IPs for searchhead instances"
  type = "map"
  default = {
    default = {
      spielwiese = [
        "10.104.198.224/28",
        "10.104.198.240/28"]
      dev = [
        "10.104.198.224/28",
        "10.104.198.240/28"]
      test = [
        "10.104.198.224/28",
        "10.104.198.240/28"]
      int = [
        "10.104.198.192/28",
        "10.104.198.208/28"]
      test = [
        "10.104.198.192/28",
        "10.104.198.208/28"]
    }
    prod = {
      spielwiese = [
        "10.104.146.128/27",
        "10.104.146.160/27"]
      dev = [
        "10.104.146.128/27",
        "10.104.146.160/27"]
      test = [
        "10.104.146.128/27",
        "10.104.146.160/27"]
      int = [
        "10.104.146.0/26",
        "10.104.146.64/26"]
      prod = [
        "10.104.146.0/26",
        "10.104.146.64/26"]
    }
  }
}
output "subnet_list" {
  value = var.subnet_cidr_map[var.workspace][var.stage]
}

# base host information
variable "hostconfig" {
  description = "Where others use rocket science we do it by hand"
  type = "map"
  default = {
    default = {
      splkp-sh01: {
        ip: "10.104.146.194",
        az: "eu-ch-01"
      },
      splkp-sh02: {
        ip: "10.104.146.210",
        az: "eu-ch-02"
      },
      splkp-id01: {
        ip: "10.104.146.199",
        az: "eu-ch-02"
      },
      splkp-id02: {
        ip: "10.104.146.215",
        az: "eu-ch-02"
      },
      splkp-sy01: {
        ip: "10.104.146.202",
        az: "eu-ch-02"
      },
      splkp-sy02: {
        ip: "10.104.146.218",
        az: "eu-ch-02"
      },
    }
    prod = {
      splkp-sh01: {
        ip: "10.104.146.2",
        az: "eu-ch-01"
      },
      splkp-sh02: {
        ip: "10.104.146.66",
        az: "eu-ch-02"
      },
      splkp-id01: {
        ip: "10.104.146.17",
        az: "eu-ch-02"
      },
      splkp-id02: {
        ip: "10.104.146.80",
        az: "eu-ch-02"
      },
      splkp-sy01: {
        ip: "10.104.146.52",
        az: "eu-ch-02"
      },
      splkp-sy02: {
        ip: "10.104.146.119",
        az: "eu-ch-02"
      },
    }
  }
}
output "hostconfig" {
  value = var.hostconfig[var.workspace]
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
