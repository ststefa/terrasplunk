# do not allow az as parameter to guarantee strict placement logic based on name
#variable "az" {
#  description = "Availability zone"
#}

variable "autorecover" {
  description = "Whether the VM should do magic OTC failover"
  default = "false"
}

variable "name" {
  description = "Name of the instance"
}

variable "secgrp_id_list" {
  description = "List of security group id (currently using name property is preferred)"
}
