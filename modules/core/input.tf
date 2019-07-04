variable "stage" {
  description = "blue / red / test / ..."
}

variable "subnet_cidr1" {}

variable "subnet_cidr2" {}

variable "dns_servers" {
  type    = list(string)
  default = ["100.125.4.25", "100.125.0.43"]
}


