The `shared` module is a place where we can put parts of the infrastructure which are shared across all stages and which profit from having their own state. Other parts of the code are able to access this state using "foreign local" state.

Don't get confused by the redundant use of the terms "local" and "remote". Terraform documentation uses them to

1. differentiate between a `terraform.tfstate` file which is stored on the local filesystem as opposed to storing it on a remote location like Amazon S3
1. differentiate the "owned read-write" state (e.g. in the current directory or remote location) and the "imported read-only" state (e.g. in a different directory or remote location).

For clarity I'll refer to the second one not as remote state but instead as `foreign state`. Thus "foreign local state" is "read-only state stored in another directory locally on the system."

Foreign state differs from the use of modules in that a module does not have state and needs to be "instantiated" to use it. However instantiating a module also creates the resources defined in it. This means that values from a module cannot be used without instantiating it which is not always possible. Foreign state, on the other hand, allows to refer to infrastructure objects whose state is kept elsewhere. In our case we use this to reference objects which are shared among all stages. This directory should contain as few resources as possible which expresses minimal shared state between stages.


# IP capacity planning
## Test tenant
    Total subnet: 10.104.198.192/26

    TODO: Subnet is too small. We need to either make it a /25 or develop an idea how to use it "shared" between stages because currently the network has to be perfectly symetrical between test and prod tenant.

    prod subnet ("netA")
        10.104.198.192/28 (usable 10.104.198.194 - 10.104.198.206, 13 IPs)
        10.104.198.208/28 (usable 10.104.198.210 - 10.104.198.222, 13 IPs)
    
        Searchhead area (2*4)
            Searchhead cluster prod (2*1)
            Searchhead cluster preprod (2*1)
            Searchhead cluster ITSI (2*1)
            Searchhead cluster ES (2*1)
        Indexer area (2*1)
            Indexer prod (2*1)
        Supplemental area (2*6)
            Heavy Forwarder prod (2*1)
            syslog (2*1)
            License Master + Deployment Server + Monitor Console  ("tool-ts") (1*1)
            Cluster Master (1*1)
            Monitoring? (2*1)
            <DNS? (2*1)>
            ... more splunk things?

    spare buffer subnet ("netB")
        no space for that :-(
        smallest OTC Subnet is /28

    nonProd subnet ("netC")
        10.104.198.224/28 (usable 10.104.198.226 - 10.104.198.238, 13 IPs)
        10.104.198.240/28 (usable 10.104.198.242 - 10.104.198.254, 13 IPs)

        Searchhead area (2*2)
            Searchhead cluster test (2*2)
        Indexer area (2*2)
            Indexer test (2*2)
        Dev System Area (2*1)
        Supplemental area (2*1)
            Heavy Forwarder test (2*1)



## Prod tenant
    Total subnet: 10.104.146.0/24

    prod subnet ("netA")
        10.104.146.0/26 (usable 10.104.146.2 - 10.104.146.62, 61 IPs)
        10.104.146.64/26 (usable 10.104.146.66 - 10.104.146.126, 61 IPs)

        Searchhead area (2*12)
            either
                Searchhead cluster prod+ITSI (2*8)
            or
                Searchhead cluster prod  (2*5)
                Searchhead cluster ITSI (2*3)
            Searchhead cluster preprod (2*3)
            Searchhead cluster ES (2*1)
        Indexer area (2*20)
            Indexer prod (2*20)
        Supplemental area (2*13)?
            Heavy Forwarder prod (2*5)
            syslog (2*4)
            License Master + Deployment Server + Monitor Console  ("tool-ts") (1*1)
            Cluster Master (1*1)
            Monitoring? (2*1)
            <DNS? (2*1)>
            ... more splunk things?

    spare buffer subnet ("netB")
        10.104.146.128/27 (usable 10.104.146.130 - 10.104.146.158, 29 IPs)
        10.104.146.160/27 (usable 10.104.146.162 - 10.104.146.190, 29 IPs)

        Prod and nonProd can extend into pieces of this buffer. I.e. prod from
        bottom and nonProd from top.

    nonProd subnet ("netC")
        10.104.146.192/27 (usable 10.104.146.194 - 10.104.146.223, 29 IPs)
        10.104.146.224/27 (usable 10.104.146.226 - 10.104.146.254, 29 IPs)

        Searchhead area (2*2)
            Searchhead cluster test (2*2)
        Indexer area (2*5)
            Indexer test (2*5)
        Dev System Area (2*10)
        Supplemental area (2*5)
            Heavy Forwarder test (2*5)

# Manual tweaking of network objects

The current setup does not (yet) manage the network setup. While this violates "Infrastructure As Code" (IAC) rules ("everything is code") it is currently setup like that because we are jump-start beginners who a supposed to create production grade infrastructure. So we opted out of managing the most crucial components for now. As a result, some manual prepwork regarding the networks needs to be done. Details on how to setup the network components reach beyond the scope of this readme and are only outlined here. Documented test code for managing VPC networks can be found at https://gitlab-tss.sbb.ch/ssteine2/vpctest.

1. Using the OTC web gui, create a new VPC "splunk-vpc" with six subnets. Place the vpc *inside* the splunk project eu-ch_splunk and not on the top level eu-ch. The subnets should be named "splunk-subnet[abc]-az1" in AZ1 and "splunk-subnet[abc]-az2" in AZ2.
2. Create a vpc peering "splunk-peering" between the splunk-vpc and the tenants hub vpc (e.g. tsch_rz_t_hub).
3. Accept the peering request on the tenants hub vpc.
4. Add the peer routing. This is 0.0.0.0/0 as a local route and the dedicated ip range of the peer vpc (e.g. 10.104.146.0/24 in case of the prod vpc) as a peer route.
5. The VPC construct on OTC is an attempt to shortcut the creation of openstack router, network and subnet. It tries to simplify this by making the network creation implicit. Unfortunately this has the side effect that the networks are all named like the vpc which makes them hard to reference in terraform code:

    ```
    $ openstack --os-cloud otc-sbb-p network list
    +--------------------------------------+--------------------------------------+--------------------------------------+
    | ID                                   | Name                                 | Subnets                              |
    +--------------------------------------+--------------------------------------+--------------------------------------+
    | 25abde7a-d8d2-444e-8c9f-78bb113ffa5b | a3c29b56-571b-4346-9252-68693a2909bf | b723a2fd-d525-4922-8991-d71d20a42b75 |
    | 2b842d2f-1331-451d-b35a-78ca61752294 | a3c29b56-571b-4346-9252-68693a2909bf | 42f3f53d-323f-4b99-8f71-74198b049d5b |
    | 531e6c12-f773-4550-91ec-b4addc2c8c3a | a3c29b56-571b-4346-9252-68693a2909bf | d20ca76d-c0d0-44f9-be47-7523a7f16964 |
    | 89a7ec0e-891f-4b24-9979-b10c0334e14d | a3c29b56-571b-4346-9252-68693a2909bf | 2483e5c2-3f60-49a3-b402-5990a806f1c9 |
    | ea9cf6ee-ecd7-4166-bbb1-337b784ef508 | a3c29b56-571b-4346-9252-68693a2909bf | e02e6bc6-7bfe-42ff-8bf9-88cdfcfc2e9f |
    | f1ff2600-d4e4-4c0a-8851-e9603e6dcbc3 | a3c29b56-571b-4346-9252-68693a2909bf | c7f4430a-1d99-4eb3-b962-0c4c42b36218 |
    +--------------------------------------+--------------------------------------+--------------------------------------+
    ```
    However we need to reference the network in several places like e.g. the ECS network config. It is fragile to reference them by id because ids (apart from being unreadable) should generally be considered ephemeral. They could be referenced by CIDR but that seems error prone. Therefore, we rename them in analogy to the subnets in order to make them more intuitive to reference. This approach has the ugly drawback that it violates iac "everything is code" rule because it cannot be done with terraform itself. But as we do not currently manage the network objects with terraform anyway this seems acceptable. We need the openstack cli to do this:

    ```
    $ openstack --os-cloud otc-sbb-p subnet list
    +--------------------------------------+--------------------+--------------------------------------+-------------------+
    | ID                                   | Name               | Network                              | Subnet            |
    +--------------------------------------+--------------------+--------------------------------------+-------------------+
    | 2483e5c2-3f60-49a3-b402-5990a806f1c9 | splunk-subnetC-az2 | 89a7ec0e-891f-4b24-9979-b10c0334e14d | 10.104.146.224/27 |
    | 42f3f53d-323f-4b99-8f71-74198b049d5b | splunk-subnetA-az1 | 2b842d2f-1331-451d-b35a-78ca61752294 | 10.104.146.0/26   |
    | b723a2fd-d525-4922-8991-d71d20a42b75 | splunk-subnetB-az2 | 25abde7a-d8d2-444e-8c9f-78bb113ffa5b | 10.104.146.160/27 |
    | c7f4430a-1d99-4eb3-b962-0c4c42b36218 | splunk-subnetA-az2 | f1ff2600-d4e4-4c0a-8851-e9603e6dcbc3 | 10.104.146.64/26  |
    | d20ca76d-c0d0-44f9-be47-7523a7f16964 | splunk-subnetC-az1 | 531e6c12-f773-4550-91ec-b4addc2c8c3a | 10.104.146.192/27 |
    | e02e6bc6-7bfe-42ff-8bf9-88cdfcfc2e9f | splunk-subnetB-az1 | ea9cf6ee-ecd7-4166-bbb1-337b784ef508 | 10.104.146.128/27 |
    +--------------------------------------+--------------------+--------------------------------------+-------------------+
    
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netA-az1 2b842d2f-1331-451d-b35a-78ca61752294
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netA-az2 f1ff2600-d4e4-4c0a-8851-e9603e6dcbc3
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netB-az1 ea9cf6ee-ecd7-4166-bbb1-337b784ef508
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netB-az2 25abde7a-d8d2-444e-8c9f-78bb113ffa5b
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netC-az1 531e6c12-f773-4550-91ec-b4addc2c8c3a
    $ openstack --os-cloud otc-sbb-p network set --name splunk-netC-az2 89a7ec0e-891f-4b24-9979-b10c0334e14d
    
    $ openstack --os-cloud otc-sbb-p network list
    +--------------------------------------+--------------------+--------------------------------------+
    | ID                                   | Name               | Subnets                              |
    +--------------------------------------+--------------------+--------------------------------------+
    | 25abde7a-d8d2-444e-8c9f-78bb113ffa5b | splunk-netB-az2    | b723a2fd-d525-4922-8991-d71d20a42b75 |
    | 2b842d2f-1331-451d-b35a-78ca61752294 | splunk-netA-az1    | 42f3f53d-323f-4b99-8f71-74198b049d5b |
    | 531e6c12-f773-4550-91ec-b4addc2c8c3a | splunk-netC-az1    | d20ca76d-c0d0-44f9-be47-7523a7f16964 |
    | 89a7ec0e-891f-4b24-9979-b10c0334e14d | splunk-netC-az2    | 2483e5c2-3f60-49a3-b402-5990a806f1c9 |
    | ea9cf6ee-ecd7-4166-bbb1-337b784ef508 | splunk-netB-az1    | e02e6bc6-7bfe-42ff-8bf9-88cdfcfc2e9f |
    | f1ff2600-d4e4-4c0a-8851-e9603e6dcbc3 | splunk-netA-az2    | c7f4430a-1d99-4eb3-b962-0c4c42b36218 |
    | 0a2228f2-7f8a-45f1-8e09-9039e1d09975 | admin_external_net | f2da9b91-3cc1-4dde-a5f7-a603aa65a2c1 |
    +--------------------------------------+--------------------+--------------------------------------+
    ```
    We can now refer to the networks by name (e.g. name="splunk-netA-az1")
