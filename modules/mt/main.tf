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

module "mt-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.searchhead-secgrp_id]
}
