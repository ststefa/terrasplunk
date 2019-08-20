# do not allow az as parameter to guarantee strict placement logic based on name
#variable "az" {
#  description = "Availability zone"
#}

variable "autorecover" {
  description = "Whether the VM should do magic OTC failover"
  default     = "false"
}

variable "instance_name" {
  description = "Name of the instance, e.g. splw0ix01"
}

variable "flavor" {
  description = "Flavor (aka sizing) of the instance"
}

variable "secgrp_id_list" {
  type        = set(string)
  description = "Optional additional security group ids (currently using name property is preferred)"
  default     = []
}
