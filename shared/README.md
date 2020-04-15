# shared state

The `shared` module is a place where we can put parts of the infrastructure which are shared across all stages on a tenant and which profit from having their own state. Other parts of the code are able to access this state using foreign state.

Don't get confused by the redundant use of the terms "local" and "remote". Terraform documentation uses them to

1. differentiate between a `terraform.tfstate` file which is stored on the local filesystem as opposed to storing it on a remote location like Amazon S3
2. differentiate the "owned read-write" state (e.g. in the current directory or remote location) and the "imported read-only" state (e.g. in a different directory or remote location).

For clarity I'll refer to the second one not as *remote state* but instead as **foreign state**. Thus "foreign local state" would be "read-only state stored in another directory locally on the system."

Foreign state differs from the use of modules in that a module does not have state and needs to be "instantiated" to use it. However instantiating a module also creates the resources defined in it. This means that values from a module cannot be used without instantiating it which is not always possible. Foreign state, in contrast, allows to refer to infrastructure objects whose state is kept elsewhere. In our case we use this to reference objects which are shared among all stages of a tenant. This directory should contain as few resources as possible which expresses minimal shared infrastructure between stages. Minimal inter-stage sharing should be a good idea to minimize dependencies and thereby improve robustness.
