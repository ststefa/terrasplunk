variable "stage" {
  description = "dev / apptest / ..."
}

variable "name" {
  description = "Sequential number of indexer instance"
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
  description = "Interface that VM depends on"
}

variable "secgrp_id" {
  description = "Security group id"
}
