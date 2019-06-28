data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../core/terraform.tfstate"
  }
}

module "indexer" {
  source = "../../../modules/indexer"
  cidr = "$(data.terraform_remote_state.core)"
  vmname = "splunk1"
  ip = "10.0.1.10"
}