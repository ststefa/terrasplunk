# Splunk> hardware layer

<!-- TOC -->

- [Splunk> hardware layer](#splunk-hardware-layer)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
  - [Code architecture](#code-architecture)
    - [Preconditions](#preconditions)
    - [Design goals](#design-goals)
    - [Project layout](#project-layout)
  - [Usage](#usage)
    - [General](#general)
    - [Terraform usage](#terraform-usage)
    - [To get started with this project](#to-get-started-with-this-project)
      - [on the test tenant](#on-the-test-tenant)
      - [on the production tenant](#on-the-production-tenant)
  - [Operating](#operating)
    - [Operating activities](#operating-activities)
      - [lock](#lock)
      - [apply, destroy](#apply-destroy)
      - [list](#list)
  - [Provisioning](#provisioning)
    - [Thoughts on provisioning](#thoughts-on-provisioning)
    - [Implementation](#implementation)
  - [Contributing](#contributing)
  - [Open Points (notes to self)](#open-points-notes-to-self)
    - [Asymetry between tenants](#asymetry-between-tenants)
    - [Duplicate hostnames](#duplicate-hostnames)
    - [New resource-level for_each meta-argument](#new-resource-level-for_each-meta-argument)

<!-- /TOC -->

## Overview

This project is about creating and maintaining the splunk platform.

It is the next evolutionary step after chewing on terraform for a while. See the `splunkprod` project for that. There is a superb talk by Nicki Watt recorded on Hashiconf which elaborates on the phases of terraform code. See

<https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments>

which leads to

<https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s>

While the `splunkprod` has a **multi terralith** structure this project restructures it to a **terraservice** setup which seems to be an appropriate setup for the planned level of collaboration and complexity.

## Prerequisites

The network is not (yet) managed on this version of the code but only referenced to. The network objects need to be setup as described in the `shared` directory.

## Code architecture

### Preconditions

To understand the reasoning for the code layout it might be helpful to know the preconditions:

- We use two symmetrical network setups on two different tenants. The network is shared over stages, i.e.there is no symmetry between networks and stages (e.g.there is a "dev" stage but no "dev" network).
- Stages are symmetrical between tenants
- Stages are not symmetrical to each other, e.g.the production stage contains different systems than the test stage. I.e.the stages do not just differ by number of VMs but also by structure. For example there are no syslog instances on the "t0" (test) stage.
- We don't have DNS as an OTC feature on our OTC-private installation and thus IPs need to be assigned statically

### Design goals

- Safe ourselves from making catastrophic mistakes
- Be flexible towards expected changes as far as possible
- Be DRY / avoid redundancy
- Minimize risk of human error, ensure consistency through code
- Be self-contained and do not rely on any organizational dependencies (e.g.existence of DNS entries)

### Project layout

The project is structured into several parts

- `bin` contains supplementary code like scripts
- `lib` contains artifacts required somewhere in the terraform process
- `modules` contains terraform modules which are used to compose the infrastructure
- `shared` contains code for infrastructure which is shared among stages
- `stages` contains one directory for each stage. Each directory contains code for that stage. The code is mostly composed from modules.

Each top-level directory contains an additional README.md to document further details.

Each terraform directory/module is structured in a default layout as proposed by Hashicorp:

- `input.tf` contains all (mandatory as well as optional) input parameters
- `main.tf` contains the infrastructure objects
- `output.tf` contains the output parameters which can be referenced by other objects

Changes between tenants and stages are factored out into the `variables` module as much as possible. It encapsulates e.g.changes in IP addresses or tenant names. By doing so it becomes somewhat safer to compose code in the stages. For further details see `modules/README.md`

## Usage

### General

We have split up the infrastructure between tenants (test and prod tenant) as well as between stages (dev/test/... ). Each stage has a separate directory in the `stages/` tree where its code is kept. In each stage directory you can have two **terraform workspaces** which are `default` and `production` .

We thus have two "axis" by which we separate terraform state, the *tenant axis* and the *stage axis*. By doing so we have two equivalent code paths for any stage. I.e.we can test modifications to any stage on the test tenant before bringing them to the production tenant.

This was done because there are major differences (i.e.not just in size but also in structure) between stages because they are used for different purposes. E.g.there will be no syslog nodes on the t0 stage. This would lead to untestable code if we had no other axis to differentiate state.

The workspaces are

- "default" for the test tenant tsch_rz_t_001. This workspace implicitly exists without creating it.
- "production" for the production tenant tsch_rz_p_001. This workspace has to be explicitly created using `terraform workspace`

More stages and/or workspaces might be added.

The infrastructure in the the `stages/` is composed from modules which are mostly cloud-provider neutral to ease migration to different cloud platforms. By using an additional abstraction layer the code could probably be made completely cloud-provider-neutral. However this has not been implemented for the sake of simplicity and costs.

### Terraform usage

Hashicorp provides a comprehensive documentation site for terraform which details the language as well as all the providers that are used to build up infrastructure.

Some places to visit:

- Download and setup: <https://www.terraform.io/downloads.html>
- Introduction: <https://www.terraform.io/intro/index.html>
- The language: <https://www.terraform.io/docs/configuration/index.html>
- The OpenStack provider: <https://www.terraform.io/docs/providers/openstack/index.html>
- The OpenTelekomCloud provider: <https://www.terraform.io/docs/providers/opentelekomcloud/index.html>
- About expressions: <https://www.terraform.io/docs/configuration/expressions.html>
- About state: <https://www.terraform.io/docs/state/index.html>
- About workspaces: <https://www.terraform.io/docs/state/workspaces.html>

Basic terraform setup

1. Download and install terraform on your computer
1. Export your OTC credentials (see provider resource in any \<stage\>/input.tf)

### To get started with this project

If you have not already done so you might want to install the `openstack` and `aws` commandline clients. This is not a requirement. It's just handy for debugging if you don't like clicking in Web GUIs. Start at <https://docs.openstack.org/python-openstackclient/> and <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html> if you don't know how to do that. Also make sure you have python `boto3` installed because the dynamic inventory uses it. It is availyble through `pip` (`pip3 install boto3`).

Next, setup your cloud credentails. The terraform state is kept on AWS S3. The infrastructure is built on OTC. Hence you need access to both cloud providers.

For AWS, the code assumes a profile named **sbb-splunk** in your `~/.aws/credentials` like this:

``` shell
$ cat ~/.aws/credentials
[sbb-splunk]
aws_access_key_id = <sbb-splunk-access-key>
aws_secret_access_key = <sbb-splunk-secret-key>
```

The AWS credentials are not personal. They are exclusively used for this project and shared among project members. The actual values for these keys are stored in PasswordSafe. Look for splunk_otc_2020.

To access the OTC the code assumes your credentials being exported as variables like this

``` shell
export TF_VAR_username=<otc-username>
export TF_VAR_password=<otc-password>
```

Make sure to escape the values properly in case they contain special characters which would otherwise be substituted by the shell. It is usually good practise to enclose the password in ''s.

For the terraform remote state to work the required objects on AWS S3 and DynamoDB have to be created (if they do not exist already). The code assumes a bucket named **sbb-splunkterraform-prod** and a DynamoDB table called **splunkterraform**. For details on setting these up visit <https://www.terraform.io/docs/backends/types/s3.html>

If you've prepared your cloud setup, resume...

#### on the test tenant

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

#### on the production tenant

- Create shared resources first:
  - `cd shared`
  - `terraform workspace new production`
  - Work through shared/README.md for required manual network setup
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

- Create any stage
  - `cd stages/<any>`
  - `terraform workspace new production`
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

Don't break stuff on the production tenant! Feel free to break everything on the test tenant. I.e.do not just yet create the terraform production workspace until you know what you're doing. As long as you stick with the default terraform workspace you can only break things on the test tenant. This is fine.

As an additional security net you should use different credentials on the test and prod tenant. This will safe you from accidentally using the wrong workspace / wrong tenant.

## Operating

This project contains a central operator-friendly shell script `bin/tspl_terraform.sh`. The script is meant to make it easier to perform certain terraform operations by offering a uniform invocation mechanism. For the most part it is just a simple shell wrapper around more complex procedures. For the technically curious it might serve as an entrypoint to traverse and understand typical activities. Try `bin/tspl_terraform.sh -h` to get started.

### Operating activities

#### lock

Explicitly lock the terraform remote state on AWS S3. This can be used to save oneself of appliying something to a stage he did not intend.

A lock can be removed using `terraform force-unlock <Lock ID>`.

For restoring back the lock, use `bin/tspl_terraform.sh lock <tenant> <stage>`.

#### apply, destroy

Wrapper around the terraform functions of the same name, but requiring tenant and stage as arguments. Terraform would natively choose tenant and stage based on current directory and terraform workspace instead.

One may optionally specify filters which are used to narrow down the systems to smaller groups. E.g. "only indexers in AZ2" would translate to specifying "--type ix --az 2".

#### list

Query server instances from remote state. Useful for being used in other scripting to create lists of splunk server names. Its logic is also used for other operations which allow to specify filters. So it is useful to test out filter rules before applying or destroying.

## Provisioning

### Thoughts on provisioning

Once the base infrastructure has been created with terraform the next most important step is the provisioning. Provisioing is a term commonly used for the process of turning the empty infrastructure into its real, usable state. It encompasses all the steps required from installing and configuring software, through configuring the relations between instances, to finally setting up and managing entry- and exit-points of the platform. A key point must be to ensure that this entire process is automated without exception so that rebuilds can be fluent and without human intervention.

Multiple approaches how this can be done are available and there is (afaik) currently no proven and generally applicable "best of breed" solution. Some use state definition tools like salt or puppet which correspond to the declarative nature of terraform. Some prefer a more procedural way using ansible or plain bash. There are also tools like `packer` (<https://www.packer.io/>) which aim to use preconfigured images. Each of these have their pros and cons which are outside of the scope of this readme.

A key requirement is that arbitrary data from terraform can be passed to the provisioning step, e.g.disk device names and instance names. This is very important because it is likely that the provisioning will need arbitrary and not yet known pieces of information about the terraformed infrastructure. A good solution will thus have to use a generic mechanism which is capable of transferring arbitrary data to the provisioning process.

There are multiple approaches how to pass arbitrary data to the provisioning, among them:

- Keep the terraform step separate from the provisioning step by first building everything up with terraform and then using some code to use the terraform state as an input. The terraform state contains a complete description of all parameters. This has the drawback of having two separate processes which might complicate automation. Also it requires to execute steps in a specific, human-made order which is contrary to a declarative approach.

- Use terraform `local-exec` provisioners which create parameter files. Any resource can add content to theese parameter files. A separate provisioning process can use it as input data to perform the provisioning. While this might make it possible to couple terraforming and provisioning closer together it might also make the terraform code more complicated.

### Implementation

For now we've chosen to build a mechanism which fully exposes the complete terraform state including all tenants as a single json structure. It is then up to the provisioning process to extract the relevant information. While this sure is not the most efficient approach it is the simplest one and still allows maximum flexibility on the provisioner side. Optimizations could be implemented (e.g.just passing parts of the full state) if this becomes necessary. Tests have shown that this will probably not be necessary for what we have planned.

To obtain the terraform data a provisioner uses the `bin/build_state.py` executable which will write the full terraform state as a json structure to stdout. The structure looks like this

``` json
{
    tenant1: {
        shared: {
            <shared state>
        }
        stage1: {
            <stage1 state>
        },
        stage2: {
            <stage2 state>
        },
        ...
    },
    tenant2: {
        shared: {
            <shared state>
        }
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

While the structure is deterministic, the sort order is not. I.e.there is no guarantee in which order the tenants, shared or stages will appear in the output.

A provisioning process can consume the json data from stdin and apply its parsing logic to extract required information.

## Contributing

For any suggestion, improvment, correction, etc.open a branch with a descriptive name (which explains the goal of the update) and assign it to a repo maintainer.

Otherwise, if you don't feel brave enough to edit code (this shouldn't be the case :simple_smile:), open an issue and assign it to a repo maintainer.

## Open Points (notes to self)

### Asymetry between tenants

The current logic does allow to have a different number of VMs between stages but not between tenants. Feature toggles based on existence of VM names defined in the variables module might solve this (<https://medium.com/capital-one-tech/building-feature-toggles-into-terraform-d75806217647>)

### Duplicate hostnames

The current logic uses the same hostnames on both tenants. While this is fine for now it might lead to conflicts should we decide to register the names in a DNS server for _both_ tenants. Currently none are registered but it might well be that registering prod-tenant-vms will be requested. Maybe this could be solved using subdomains for tenants. Otherwise the vm namimg concept must be changed.

### New resource-level for_each meta-argument

The introduction of the for_each on resources-level might allow for a complete redesign of the code and arrange it around a custom map of server definitions. This could be used to make the code completely provider-agnostic.
