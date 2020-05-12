locals {
  stage = substr(var.instance_name, 3, 2)
}

module "variables" {
  source = "../../modules/variables"

  workspace = terraform.workspace
  stage     = local.stage
}

data "terraform_remote_state" "shared" {
  #backend = "local"
  #config = {
  #  path = module.variables.shared_statefile
  #}
  backend = "s3"
  config  = module.variables.s3_shared_config
}

module "cm-instance" {
  source         = "../../modules/genericecs"
  instance_name  = var.instance_name
  secgrp_id_list = [data.terraform_remote_state.shared.outputs.searchhead-secgrp_id]
  autorecover    = "true"
}
