# Overview

This module is about creating and maintaining the splunk platform.

It is the next evolutionary step after chewing on terraform for a while. See
the `splunkprod` project for that.

There is a superb talk by Nicki Watt recorded on Hashiconf which elaborates on
the phases of terraform code. See

https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments

which leads to

https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s

While the `splunkprod` has a *multi terralith* structure this project
restructures it to a *terramod* setup which seems to be an appropriate setup
for the planned level of collaboration and complexity.

# Usage

1. Download and install terraform for your computer
2. Export your Cload credentials (see envs/*/terraform.tfvars)
3. cd envs/<any>
4. terraform plan
5. terraform apply

Don't break stuff!

# Provisioning

Once the base infrastructure has been created with terraform the next most
important step is the provisioning. Provisioing is a term commonly used for the
process of turning the empty infrastructure into its real, usable state. It
encompasses all the steps required from installing and configuring software,
through configuring the relations between instances, to finally setting up and
managing entrypoints and eit points of the platform.

Multiple approaches how this can be done are available and there is (to my
knowledge) currently no proven and generally applicable "best of breed"
solution. Oftentimes state definition tools like salt or pupet are used. Some
prefer a more procedural way using ansible or plain bash. There are tools like
`packer` (https://www.packer.io/) which aim to use preconfigured packages.

A key requirement is that arbitrary data from terraform can be passed to the
provisioning step, e.g. disk device names and instance names. This is very
important because it is likely that the provisioning will need arbitrary and
not yet known pieces of information about the terraformed infrastructure. A
good solution will thus have to use a generic mechanism which is capable of
transferring arbitrary data to the provisioner.

The current approach uses terroform `local-exec` provisioners which create
parameter files. Any resource can add to this parameter files. A separate
provisioning script can use it as input data to perform the provisioning.