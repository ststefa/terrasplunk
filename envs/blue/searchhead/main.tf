data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../core/terraform.tfstate"
  }
}

module "searchhead" {
  source = "../../../modules/searchhead"
  cidr = "$(data.terraform_remote_state.core)"
  dmz_cidr = "$(var.dmz_cidr)"
  priv_cidr = "$(var.priv_cidr)"
}