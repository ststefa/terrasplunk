variable "stage" {
  description = "dev / apptest / ..."
}

variable "name" {
  description = "Name of the instance"
}

variable "az" {
  description = "Availability zone"
}

variable "keypair_id" {
  description = "id of ssh access key"
}

variable "flavor" {
  default = "s2.medium.4"
}

variable "network_id" {
  description = "Network id"
}

variable "ip" {
  description = "VM IP"
}

variable "interface" {
  description = "Interface that VM depends on. If omitted, provisioning might fail beause the VM is accessed earlier then the network is built"
}

variable "secgrp_id" {
  description = "Security group id"
}
