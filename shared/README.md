The `shared` module is a place where we can put parts of the infrastructure which are shared across all stages on a tenant and which profit from having their own state. Other parts of the code are able to access this state using "foreign local" state.

Don't get confused by the redundant use of the terms "local" and "remote". Terraform documentation uses them to

1. differentiate between a `terraform.tfstate` file which is stored on the local filesystem as opposed to storing it on a remote location like Amazon S3
1. differentiate the "owned read-write" state (e.g. in the current directory or remote location) and the "imported read-only" state (e.g. in a different directory or remote location).

For clarity I'll refer to the second one not as *remote state* but instead as `foreign state`. Thus "foreign local state" is "read-only state stored in another directory locally on the system."

Foreign state differs from the use of modules in that a module does not have state and needs to be "instantiated" to use it. However instantiating a module also creates the resources defined in it. This means that values from a module cannot be used without instantiating it which is not always possible. Foreign state, in contrast, allows to refer to infrastructure objects whose state is kept elsewhere. In our case we use this to reference objects which are shared among all stages of a tenant. This directory should contain as few resources as possible which expresses minimal shared infrastructure between stages. Minimal inter-stage sharing should be a good idea to minimize dependencies and thereby improve robustness.


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
