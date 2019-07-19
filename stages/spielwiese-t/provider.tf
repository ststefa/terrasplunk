provider "openstack" {
  domain_name = "tsch_rz_t_001"
  #tenant_name = "eu-ch"
  #user_name   = var.username
  #password    = var.password
  # use openstack cloud config (~/.config/openstack/clouds.yaml) instead of username/password
  # see
  # https://docs.openstack.org/python-openstackclient/stein/configuration/index.html
  cloud = "otc-sbb-t"
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "null" {
}

