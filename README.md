# Overview
This project is about creating and maintaining the splunk platform.

It is the next evolutionary step after chewing on terraform for a while. See the `splunkprod` project for that. There is a superb talk by Nicki Watt recorded on Hashiconf which elaborates on the phases of terraform code. See

https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments

which leads to

https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s

While the `splunkprod` has a **multi terralith** structure this project restructures it to a **terraservice** setup which seems to be an appropriate setup for the planned level of collaboration and complexity.


# Prerequisites
The network is not (yet) managed on this version of the code but only referenced to. The network objects need to be setup as described in the `shared` directory.


# Code architecture
## Preconditions
To understand the reasoning for the code layout it might be helpful to know the preconditions:

- We use two symmetrical network setups on two different tenants. The network is shared over stages, i.e. there is no symmetry between networks and stages (e.g. there is a "dev" stage but no "dev" network).
- Stages are symmetrical between tenants
- Stages are not symmetrical to each other, e.g. the production stage contains different systems than the test stage. I.e. the stages do not just differ by number of VMs but also by structure. For example there are no indexer instances on the "qa" (quality assurance) stage.
- We don't have DNS as an OTC feature on our OTC-private installation and thus IPs need to be assigned statically

## Design goals
- Safe ourselves from making catastrophic mistakes
- Be flexible towards expected changes as far as possible
- Be DRY / avoid redundancy
- Minimize risk of human error, ensure consistency through algorithms

## Project layout
The project is structured into several parts

- `lib` contains supplementary code like scripts
- `modules` contains terraform modules which are used to compose the infrastructure in the stages
- `shared` contains code and state for infrastructure which is shared among stages
- `stages` contains one directory for each stage. Each directory contains code and state for that stage. The code is mostly composed from modules.

Each top-level directory contains an additional README.md to document further details.

Each terraform directory/module is structured in a default layout as proposed by Hashicorp:

- `input.tf` contains all (mandatory as well as optional) input parameters
- `main.tf` contains the infrastructure objects
- `output.tf` contains the output parameters which can be referenced by other objects

Changes between tenants and stages are factored out into the `variables` module as much as possible. It encapsulates e.g. changes in IP addresses or tenant names. By doing so it becomes somewhat safer to compose code in the stages. For further details see `modules/README.md`


# Usage
## General
We have split up the infrastructure between tenants (test and prod tenant) as well as between stages (dev/test/...). Each stage has a separate directory in the `stages/` tree where its state is kept. In each stage directory you can have two **terraform workspaces** which are `default` and `production`.

We thus have two "axis" by which we separate terraform state, the *tenant axis* and the *stage axis*. By doing so we have two equivalent code paths for any stage. I.e. we can test modifications to any stage on the test tenant before bringing them to the production tenant.

This was done because there are major differences (i.e. not just in size but also in structure) between stages because they are used for different purposes. E.g. there will be no indexing nodes on the qa stage. This would lead to untestable code if we had no other axis to differentiate state.

The workspaces are

- "default" for the test tenant tsch_rz_t_001. This workspace implicitly exists without creating it.
- "production" for the production tenant tsch_rz_p_001. This workspace has to be explicitly created using `terraform workspace`

More stages and/or workspaces might be added.

## Terraform usage
Hashicorp provides a comprehensive documentation site for terraform which details the language as well as all the providers that are used to build up infrastructure.

Some places to visit:

- Download and setup: https://www.terraform.io/downloads.html
- Introduction: https://www.terraform.io/intro/index.html
- The language: https://www.terraform.io/docs/configuration/index.html
- The OpenStack provider: https://www.terraform.io/docs/providers/openstack/index.html
- The OpenTelekomCloud provider: https://www.terraform.io/docs/providers/opentelekomcloud/index.html
- About expressions: https://www.terraform.io/docs/configuration/expressions.html
- About state: https://www.terraform.io/docs/state/index.html
- About workspaces: https://www.terraform.io/docs/state/workspaces.html

Basic terraform setup
1. Download and install terraform on your computer
1. Export your OTC credentials (see provider resource in any <stage>/input.tf)

## To get started with this project...

### ...on the test tenant

- Create shared resources first:
    - `cd shared`
    - Work through shared/README.md for required manual network setup
    - `terraform init`
    - `terraform plan`
    - `terraform apply`
- Create any stage
    - `cd stages/<any>`
    - `terraform init`
    - `terraform plan`
    - `terraform apply`

### ...on the production tenant

- Create shared resources first:
    - `cd shared`
    - Work through shared/README.md for required manual network setup
    - `terraform workspace new production`
    - `terraform workspace select production`
    - `terraform init`
    - `terraform refresh`
    - `terraform plan`
    - `terraform apply`
- Create any stage
    - `terraform workspace new production`
    - `terraform workspace select production`
    - `cd stages/<any>`
    - `terraform init`
    - `terraform refresh`
    - `terraform plan`
    - `terraform apply`

Don't break stuff on the production tenant! Feel free to break everything on the test tenant. I.e. do not just yet create the terraform production workspace until you know what you're doing. As long as you stick with the default terraform workspace you can only break things on the test tenant. This is fine.

As an additional security net you should use different credentials on the test and prod tenant. This will safe you from accidentally using the wrong workspace.

# Provisioning

## Thoughts on provisioning

Once the base infrastructure has been created with terraform the next most important step is the provisioning. Provisioing is a term commonly used for the process of turning the empty infrastructure into its real, usable state. It encompasses all the steps required from installing and configuring software, through configuring the relations between instances, to finally setting up and managing entry- and exit-points of the platform. A key point must be to ensure that this entire process is automated without exception so that rebuilds can be fluent and without human intervention.

Multiple approaches how this can be done are available and there is (afaik) currently no proven and generally applicable "best of breed" solution. Some use state definition tools like salt or puppet which correspond to the declarative nature of terraform. Some prefer a more procedural way using ansible or plain bash. There are also tools like `packer` (https://www.packer.io/) which aim to use preconfigured images. Each of these have their pros and cons which are outside of the scope of this readme.

A key requirement is that arbitrary data from terraform can be passed to the provisioning step, e.g. disk device names and instance names. This is very important because it is likely that the provisioning will need arbitrary and not yet known pieces of information about the terraformed infrastructure. A good solution will thus have to use a generic mechanism which is capable of transferring arbitrary data to the provisioning process.

I currently see two approaches to pass arbitrary data to the provisioning:

- Keep the terraform step separate from the provisioning step by first building everything up with terraform and then using some code to use the terraform state as an input. The terraform state contains a complete description of all parameters. This has the drawback of having two separate processes which might complicate automation. Also it requires to execute steps in a specific, human-made order which is contrary to a declarative approach.

- Uses terraform `local-exec` provisioners which create parameter files. Any resource can add to this parameter files. A separate provisioning process can use it as input data to perform the provisioning. While this might make it possible to couple terraforming and provisioning closer together it might also make the terraform code more complicated.

## Implementation

For now we've chosen to build a mechanism which fully exposes the complete terraform state including all tenants as a single json structure. It is then up to the provisioning process to extract the relevant information. While this sure is not the most efficient approach it is the simplest one and still allows maximum flexibility on the provisioner side. Optimizations could be implemented (e.g. just passing parts of the full state) if this becomes necessary. Tests have shown that this will probably not be necessary for what we have planned.

To obtain the terraform data a provisioner uses the `bin/build_state.py` executable which will write the full terraform state as a json structure to stdout. The structure looks like this

```
{
    shared: {
        <shared state>
    }
    tenant1: {
        stage1: {
            <stage1 state>
        },
        stage2: {
            <stage2 state>
        },
        ...
    },
    tenant2: {
        stage1: {
            <stage1 state>
        },
        stage2: {
            <stage2 state>
        },
        ...
    },
    ...
}
```

While the structure is deterministic the sort order is not. I.e. there is no guarantee in which order the tenants, shared or stages will appear in the output.

The provisioner can then read this json data from stdin and apply his parsing logic to extract required information.

# Contributing

For any suggestion, improvment, correction, etc. open a branch with a descriptive name (which it explains the goal of the update) and assign it to a repo maintainer.

Otherwise, if you don't feel brave enough to edit code (this shouldn't be the case :simple_smile:), open an [issue](https://gitlab-tss.sbb.ch/splunk/splunk_provisioning/issues) and assign it to a repo maintainer.

# Open Points (notes to self)

## Handling tfstate between multiple developers

Might use S3 if it works on OTC.

etcdv3 seems promising

## Asymetry between tenants

The current logic does allow to have a different number of VMs between stages but not between tenants. Feature toggles based on existence of VM names defined in the variables module might solve this (https://medium.com/capital-one-tech/building-feature-toggles-into-terraform-d75806217647)

## Duplicate hostnames

The current logic uses the same hostnames on both tenants. While this is fine for now it might lead to conflicts should we decide to register the names in a DNS server for _both_ tenants. Currently none are registered but it might well be that registering prod-tenant-vms will be requested. Maybe this could be solved using subdomains for tenants. Otherwise the vm namimg concept must be changed.
