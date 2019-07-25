#variable "stage" {
# description = "dev / apptest / ..."
#}

variable "name" {
  description = "Name of the instance"
}

#variable "az" {
#  description = "Availability zone"
#}

#variable "keypair_id" {
#  description = "id of ssh access key"
#}

variable "flavor" {
  default = "s2.2xlarge.4"
}

variable "autorecover" {
  default = "false"
}

variable "opt_size" {
  default = 20
}

#variable "network_id" {
#  description = "Network id"
#}
#
#variable "interface" {
#  description = "Interface that VM depends on. If omitted, provisioning might fail beause the VM is accessed earlier then the network is built"
#}

variable "secgrp_id" {
  description = "Security group id"
}
