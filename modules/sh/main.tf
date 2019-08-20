locals {
  stage = substr(var.name, 3, 2)
}

module "variables" {
  source = "../../modules/variables"

  workspace = terraform.workspace
  stage     = local.stage
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = module.variables.shared_statefile
  }
}

module "sh-instance" {
  source         = "../../modules/genericecs"
  name           = var.name
  flavor         = module.variables.flavor_sh
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}
