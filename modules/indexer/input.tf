# do not allow autorecover for indexers
#variable "autorecover" {
#  default = "false"
#}

variable "name" {
  description = "Name of the instance"
}

variable "secgrp_id" {
  description = "Security group id"
}
