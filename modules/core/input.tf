variable "stage" {}

variable "subnet_cidr" {}

variable "dns_servers" {
  type = list(string)
  default = ["100.125.4.25","100.125.0.43"]
}


