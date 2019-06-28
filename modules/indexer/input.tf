variable "stage" {}

variable "az" {
  default = "eu-ch-01"
}
variable "vmname" {
  description = "Name of the VM"
}
variable "flavor" {
  default = "s2.medium.4"
}
variable "net_id" {
  description = "Network id"
}
variable "ip" {
  description = "VM IP"
}
