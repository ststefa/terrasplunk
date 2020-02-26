locals {
  stage = substr(var.instance_name, 3, 2)
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

module "cm-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  flavor         = module.variables.flavor_cm
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.searchhead-secgrp_id]
  autorecover    = "true"
}
