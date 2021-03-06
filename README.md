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
    - [Implementation Details](#implementation-details)
  - [Contributing](#contributing)
  - [Open Points (notes to self)](#open-points-notes-to-self)
    - [Asymmetry between tenants](#asymmetry-between-tenants)
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

- `bin/` contains supplementary code like scripts
- `lib/` contains artifacts required somewhere in the terraform process
- `modules/` contains terraform modules which are used to compose the infrastructure
- `shared/` contains code for infrastructure which is shared among stages
- `stages/*/` contains one directory for each stage. Each directory contains code for that stage. The code is mostly composed from modules.

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

You might want to install the `openstack` and `aws` commandline clients. This is not strictly a requirement. It's just handy for debugging if you prefer typing over clicking. Start at <https://docs.openstack.org/python-openstackclient/> and <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html> if you don't know how to do that.

Some of the support scripts use Amazons `boto3` python code so make sure that it's installed. It is available through `pip3`. To check whether it's already installed use `pip3 list`. If it's not installed you can run `sudo pip3 install boto3`.

Next, setup your cloud credentials. The terraform state is kept on AWS S3. The infrastructure is built on OTC. Hence you need access to both of these cloud providers.

For AWS, the code assumes a profile named **sbb-splunk** in your `~/.aws/credentials` like this:

``` shell
$ cat ~/.aws/credentials
[sbb-splunk]
aws_access_key_id = <sbb-splunk-access-key>
aws_secret_access_key = <sbb-splunk-secret-key>
```

Make sure this file is chmod 600 for security reasons.

The AWS credentials are not personal. They are exclusively used for this project and shared among project members. The actual values for these keys are stored in PasswordSafe. Look for splunk_otc_2020.

To access the OTC the code assumes your credentials are configured in the openstack configuration file `~/.config/openstack/clouds.yaml`. The `clouds` sections need to be named like the tenants, i.e.

``` shell
$ cat  ~/.config/openstack/clouds.yaml
clouds:
    tsch_rz_t_001:
        auth:
            auth_url: 'https://auth.o13bb.otc.t-systems.com/v3'
            project_name: 'eu-ch_splunk'
            domain_name: 'tsch_rz_t_001'
            username: 'your-otc-uid-for-test-tenant'
            password: 'password-for-that-uid'
        region_name: 'eu-ch'
    tsch_rz_p_001:
        auth:
            auth_url: 'https://auth.o13bb.otc.t-systems.com/v3'
            project_name: 'eu-ch_splunk'
            domain_name: 'tsch_rz_p_001'
            username: 'your-otc-uid-for-prod-tenant'
            password: 'password-for-that-uid'
        region_name: 'eu-ch'
```

Unlike the terraform credentials, the OTC credentials *are* personalized. Make sure this file is also chmod 600 for security reasons.


For the terraform remote state to work, the required objects on AWS S3 and DynamoDB have to be created (if they do not exist already). The code assumes a bucket named **sbb-splunkterraform-prod** and a DynamoDB table called **splunkterraform**. For details on setting these up visit <https://www.terraform.io/docs/backends/types/s3.html>

If you've prepared your cloud setup, resume...

#### on the test tenant

- Create shared resources first:
  - `cd shared`
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
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

- Create any stage
  - `cd stages/<any>`
  - `terraform workspace new production`
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

Don't break stuff on the production tenant! Feel free to break everything on the test tenant. I.e. do not just yet create the terraform production workspace until you know what you're doing. As long as you stick with the default terraform workspace you can only break things on the test tenant. This is fine.

## Operating

This project contains a central operator-friendly shell script `bin/tspl_terraform.sh`. The script is meant to make it easier to perform common terraform operations by offering a uniform invocation mechanism. For the most part it is just a simple shell wrapper around more complex procedures. For the technically curious it might serve as an entrypoint to understand how typical activities are implemented. Try `bin/tspl_terraform.sh -h` to get started.

You should create a symbolic link of this script from your git clone to your personal `~/bin` directory so that by default it will be in your `$PATH`. All our splunk git repositories follow this approach. If you also follow the convention to link the various `bin/tspl_<something>.sh` scripts to your `~/bin` directory then most splunk operating activities can start by simply typing `tspl<tab><tab>` and then using the online help.

### Operating activities

Most commands support optional filters to narrow down the systems to smaller groups. E.g. "only indexers in availability zone 2" would translate to `--type ix --az 2`.

#### lock

Explicitly lock the terraform remote state on AWS S3. This can be used to save oneself of applying something to a stage he did not intend. It is considered good practice to lock production at all times except when actively working on it.

A lock can be removed by cd-ing to the appropriate terraform directory and workspace and then using `terraform force-unlock <Lock ID>`. If this does not sound familiar then you should get some terraform practice before continuing.

For restoring back the lock, use `bin/tspl_terraform.sh lock <tenant> <stage>`.

#### apply, destroy

Wrapper around the terraform functions of the same name, but requiring tenant and stage as arguments. Terraform would natively choose tenant and stage based on current directory and terraform workspace instead.


#### list

Query server instances from remote terraform state using `serverlist.py`. Can be used in other scripting to create lists of splunk server names. Its logic is also used for other operations which allow to specify filters. So it is useful to test out filter rules before running actual terraform operations like apply or destroy. Be aware that this mechanism is based on the current terraform state which means that it cannot be used to limit to VMs which do not (yet) exist.

## Provisioning

Once the base infrastructure has been created with terraform the next step is the provisioning. Provisioning is the process of turning the empty infrastructure into its real, usable state. It encompasses all the steps required from installing and configuring software, through configuring the relations between instances, to finally setting up and managing entry- and exit-points of the platform. A key point must be to ensure that this entire process is automated without exception so that rebuilds can be fluent and without human intervention.

We keep the terraform step separate from the provisioning step by first building everything up with terraform and then using that state as an input for the provisioning which is implemented using ansible. The terraform state contains a complete description of all parameters. required in the provisioning code.

### Implementation Details

We expose the complete terraform state including all tenants as a single json structure. It is then up to the provisioning process to extract the relevant information. While this sure is not the most efficient approach it is the simplest one and still allows maximum flexibility for the provisioning process. Optimizations could be implemented (e.g. just passing parts of the full state) but this will probably not be necessary considering the foreseeable sizing.

The provisioning queries the remote terraform state and combines it in a json structure like this

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

## Contributing

For any suggestion, improvement, correction, etc. open a branch with a descriptive name (which explains the goal of the update) and assign it to a repo maintainer.

Otherwise, if you don't feel brave enough to edit code (this shouldn't be the case :simple_smile:), open an issue and assign it to a repo maintainer.

## Open Points (notes to self)

### Asymmetry between tenants

The current logic does allow to have a different number of VMs between stages but not between tenants. Feature toggles based on existence of VM names defined in the variables module might solve this (<https://medium.com/capital-one-tech/building-feature-toggles-into-terraform-d75806217647>)

### Duplicate hostnames

The current logic uses the same hostnames on both tenants. While this is fine for now it might lead to conflicts should we decide to register the names in a DNS server for _both_ tenants. Currently none are registered but it might well be that registering prod-tenant-vms will be requested. Maybe this could be solved using subdomains for tenants. Otherwise the vm naming concept must be changed.

### New resource-level for_each meta-argument

The introduction of the for_each on resources-level might allow for a complete redesign of the code and arrange it around a custom map of server definitions. This could be used to make the code completely provider-agnostic.
