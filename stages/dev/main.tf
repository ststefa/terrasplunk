locals {
  stage = "dev"
}

# credentials can be provided using shell variables
#   export TF_VAR_username=john
#   export TF_VAR_password=secret
variable "username" {}
variable "password" {}

module "variables" {
  source = "../../modules/variables"

  workspace  = terraform.workspace
  stage      = local.stage
}
