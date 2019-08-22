variable "autorecover" {
  description = "Whether the VM should do magic OTC failover"
  default     = "false"
}

variable "instance_name" {
  description = "Name of the instance, e.g. splw0cm01"
}

variable "flavor" {
  description = "Flavor (aka sizing) of the instance"
  # use this weird contruct because variables (i.e. module.variables.flavor_default) are not allowed here
  default = "unset"
}

variable "secgrp_id_list" {
  type        = set(string)
  description = "Optional additional security group ids (currently using name property is preferred)"
  default     = []
}
