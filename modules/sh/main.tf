locals {
  stage_map = { #TODO remove, stage==var.stage
    d0 : "development"
    t0 : "test"
    q0 : "quality"
    p0 : "production"
    w0 : "spielwiese"
    u0 : "universal"
  }
  stage = local.stage_map[var.stage]
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
  name           = "spl${var.stage}${var.role}${format("%02d", var.number)}" #TODO refactor name building logic to genericecs
  secgrp_id_list = [data.terraform_remote_state.shared.outputs["searchhead-secgrp_id"]]
}
