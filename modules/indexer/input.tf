variable "stage" {
  description = "blue / red / test / ..."
}

variable "keypair_id" {
  description = "id of ssh access key"
}

variable "az" {
  description = "eu-ch-01 / eu-ch-02"
}
variable "vmname" {
  description = "Name of the VM"
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
  description = "Interface that VM depends on"
}

variable "secgrp_id" {
  description = "Security group id"
}
