module "core" {
  source = "../../../modules/core"
  subnet_cidr = "10.0.1.0/24"
  dns_servers = ["100.125.4.25","100.125.0.43"]
}

