# Overview

This module is about creating and maintaining the splunk platform.

It is the next evolutionary step after chewing on terraform for a while. See the `splunkprod` project for that.

There is a superb talk by Nicki Watt recorded on Hashiconf which elaborates on the phases of terraform code. See

https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments

which leads to

https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s

While the `splunkprod` has a *multi terralith* structure this project restructures it to a *terramod* setup which seems to be an appropriate setup for the planned level of collaboration and complexity.

# Prereqs
## Network setup
The current setup does not manage the network setup. While this violates iac rules ("everything as code") we have it setup like that because we are jump-start beginners who a supposed to create production grade infrastructure. So some prereqs regarding the networks must be prepared. Details on how to perform this setup reach beyond the scope of this readme.

1. Using the OTC webgui, create a new VPC "splunk-vpc" with all the subnets. The vpc should be located *inside* the splunk project eu-ch_splunk and not on the top level eu-ch. The subnets should be named "splunk-subnet-az[12]-[1-9]".
1. Create a vpc peering "splunk-peering" between the splunk-vpc and the tenants hub vpc (e.g. tsch_rz_t_hub).
1. Add the peer routing. This is 0.0.0.0/0 as a local route and the dedicated ip range (e.g. 10.104.146.0/24) of the vpc as a peer route.
1. Accept the peering request on the tenants hub vpc.
1. The VPC construct on OTC is an attempt to shortcut the creation of openstack router, network and subnet. It tries to simplify this by making the network creation implicit. Unfortunately this has the ugly side effect that the networks are all named like the vpc which makes them hard to reference in terraform code:

    ```
    $ openstack --os-cloud otc-sbb-t network list
    +--------------------------------------+--------------------------------------+--------------------------------------+
    | ID                                   | Name                                 | Subnets                              |
    +--------------------------------------+--------------------------------------+--------------------------------------+
    | 0c7192a0-b7a0-498a-a317-c788a27f71be | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | 8f4f6547-4152-4d4a-bb49-cd3ef855b098 |
    | 25081612-36c2-4ea5-ad1f-ece095f9be8e | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | d5b8fc09-a066-419b-80a9-a22b1f71a0bc |
    | 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | f132f729-1f9a-40ea-aefc-aa2d87163e28 |
    | b6930a97-17d2-435c-8610-694a41451ab5 | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | b3eb7367-0db3-42b6-a062-676e57b3face |
    | 0a2228f2-7f8a-45f1-8e09-9039e1d09975 | admin_external_net                   |                                      |
    +--------------------------------------+--------------------------------------+--------------------------------------+
    ```
    However we need to reference the network in several places like e.g. the ECS network config. It is fragile to reference them by id because ids (apart from being unreadable) should generally be considered ephemeral. We could reference by cidr but that's complicated and error prone. Therefore, we rename them in analogy to the subnets in order to make them easier to reference. This approach has the ugly drawback that it violates iac "everything is code" rule as it cannot be done with terraform itself but has to be done with the openstack cli:

    ```
    $ openstack --os-cloud otc-sbb-t subnet list
    +--------------------------------------+---------------------+--------------------------------------+-------------------+
    | ID                                   | Name                | Network                              | Subnet            |
    +--------------------------------------+---------------------+--------------------------------------+-------------------+
    | 8f4f6547-4152-4d4a-bb49-cd3ef855b098 | splunk-subnet-az1-2 | 0c7192a0-b7a0-498a-a317-c788a27f71be | 10.104.198.224/28 |
    | b3eb7367-0db3-42b6-a062-676e57b3face | splunk-subnet-az2-1 | b6930a97-17d2-435c-8610-694a41451ab5 | 10.104.198.208/28 |
    | d5b8fc09-a066-419b-80a9-a22b1f71a0bc | splunk-subnet-az1-1 | 25081612-36c2-4ea5-ad1f-ece095f9be8e | 10.104.198.192/28 |
    | f132f729-1f9a-40ea-aefc-aa2d87163e28 | splunk-subnet-az2-2 | 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | 10.104.198.240/28 |
    +--------------------------------------+---------------------+--------------------------------------+-------------------+
    
    $ openstack --os-cloud otc-sbb-t network set --name splunk-net-az1-1 25081612-36c2-4ea5-ad1f-ece095f9be8e
    $ openstack --os-cloud otc-sbb-t network set --name splunk-net-az2-1 b6930a97-17d2-435c-8610-694a41451ab5
    $ openstack --os-cloud otc-sbb-t network set --name splunk-net-az1-2 0c7192a0-b7a0-498a-a317-c788a27f71be
    $ openstack --os-cloud otc-sbb-t network set --name splunk-net-az2-2 8b0e7640-8b67-4c8e-9934-bf46c2a987f6
    
    $ openstack --os-cloud otc-sbb-t network list
    +--------------------------------------+--------------------+--------------------------------------+
    | ID                                   | Name               | Subnets                              |
    +--------------------------------------+--------------------+--------------------------------------+
    | 0c7192a0-b7a0-498a-a317-c788a27f71be | splunk-net-az1-2   | 8f4f6547-4152-4d4a-bb49-cd3ef855b098 |
    | 25081612-36c2-4ea5-ad1f-ece095f9be8e | splunk-net-az1-1   | d5b8fc09-a066-419b-80a9-a22b1f71a0bc |
    | 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | splunk-net-az2-2   | f132f729-1f9a-40ea-aefc-aa2d87163e28 |
    | b6930a97-17d2-435c-8610-694a41451ab5 | splunk-net-az2-1   | b3eb7367-0db3-42b6-a062-676e57b3face |
    | 0a2228f2-7f8a-45f1-8e09-9039e1d09975 | admin_external_net |                                      |
    +--------------------------------------+--------------------+--------------------------------------+
    ```
    We can now refer to the networks by name (e.g. name="splunk-net-az1-1")

# Code architecture

To understand the reasoning for the code layout it might be helpful to know the preconditions:

1. We use two perfectly symetric setups on two different tenants
2. We don't have DNS as an OTC feature on our OTC-private installation
3. Number of searchhead, indexers, ... must be easily extendable
4. The definition of the network is shared among stages due to IP range limitations
5. Stages are not identical. E.g. the production stage contains different systems than the test change (i.e. not just by number but also by structure). There are for example no indexer instances on the qa stage.

# Usage

## General
We have split up the infrastructure between tenants (test and prod tenant) as well as between stages (s/t/i/p). Each stage has a separate state directory in the `stages/` tree. In each stage directory you can have two **terraform workspaces** which are *default* (exists impclicitly) and *prod* (has to be explicitly created using `terraform workspace`).

We thus have two "axis" by which we separate terraform state, the "tenant axis" and the "stage axis". By doing so we have two equivalent code paths for any stage.

This was done because we expect to have major differences (i.e. not just in size but also in structure) between stages because they are used for different purpose. E.g. there will be no indexing nodes on the integration stage. This would lead to untestable code.

The workspaces are

- "default" for the test tenant tsch_rz_t_001
- "prod" for the production tenant tsch_rz_p_001

## Terraform usage

Hashicorp provides a great documentation site for terraform which details the language as well as all the providers that are used to build up infrastructure.

Some places to visit:

Download and setup: https://www.terraform.io/downloads.html
Introduction: https://www.terraform.io/intro/index.html
The language: https://www.terraform.io/docs/configuration/index.html
The OpenStack provider: https://www.terraform.io/docs/providers/openstack/index.html
The OpenTelekomCloud provider: https://www.terraform.io/docs/providers/opentelekomcloud/index.html
About expressions: https://www.terraform.io/docs/configuration/expressions.html
About state: https://www.terraform.io/docs/state/index.html
About workspaces: https://www.terraform.io/docs/state/workspaces.html

To get started with this project:

- Download and install terraform for your computer
- Export your OTC credentials (see provider resource in any <stage>/main.tf)
- `cd stages/<any>`
- `terraform init`
- `terraform plan`
- `terraform apply`

Don't break stuff on the production tenant. Feel free to break everything on the test tenant.


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
