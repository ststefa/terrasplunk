The `env` directory contains several distinct parts of the infrastructure.
The goal of this is to have distinct states (i.e. multiple `terraform.tfstate`
files, one per directory) to reduce the risk of catastrophic errors. To learn 
more on how a single state file easily leads to catastrophic errors please
review the talk by Nicki Watt mentioned in the toplevel README.
