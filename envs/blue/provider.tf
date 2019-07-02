provider "openstack" {
  user_name   = var.username
  password    = var.password
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch"
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "null" {
}

