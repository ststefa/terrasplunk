The `shared` module is a place where we can put parts of the infrastructure which are shared across all stages and which profit from having their own state. Other parts of the code are able to access this state using remote state.

This differs from using modules because a module does not have state and needs to be "instantiated" to use it. That means you cannot use values from a module without instantiating it. However instantiating a module also creates the resources defined in it which is impossible in some cases.

This directory should contain as little resources as possible to minimize shared use between stages.

Beware of the redundant use of the terms "local" and "remote". Terraform uses them to differentiate between a terraform.tfstate file which is stored on the local filesystem as opposed to storing it on a remote location like Amazon S3. However the terms are also used to differentiate the "owned read-write" state (e.g. in the local directory) state and the "imported read-only" state (e.g. in a different directory).

# Stage subnets and IP ranges

## Test tenant

    Total subnet: 10.104.198.192/26

    TODO: Subnet is too small. We need to either make it a /25 or develop an
    idea how to use it "shared" between stages

    prod subnet
        10.104.198.192/28 (usable 10.104.198.194 - 10.104.198.206, 13 IPs)
        10.104.198.208/28 (usable 10.104.198.210 - 10.104.198.222, 13 IPs)
    
        Searchhead area
    
            Searchhead cluster prod (2*1)+1

            Searchhead cluster preprod (2*1)+1
          
            Searchhead cluster ITSI (2*1)+1

            Searchhead cluster ES (2*1)+1

        Indexer area

            Indexer prod (2*2)

        Supplemental area
        
            Heavy Forwarder prod (2*1)
            
            syslog (2*1)

    spare buffer subnet
        no space for that :-(
        smallest OTC Subnet is /28

    nonprod subnet
        10.104.198.224/28 (usable 10.104.198.226 - 10.104.198.238, 13 IPs)
        10.104.198.240/28 (usable 10.104.198.242 - 10.104.198.254, 13 IPs)

        Searchhead area
        
            Searchhead cluster test (2*1)

        Indexer area
        
            Indexer test (2*1)

        Dev System Area

        Supplemental area
        
            Heavy Forwarder test (2*1)



## Prod tenant

    Total subnet: 10.104.146.0/24

    prod subnet
        10.104.146.0/26 (usable 10.104.146.2 - 10.104.146.62, 61 IPs)
        10.104.146.64/26 (usable 10.104.146.66 - 10.104.146.126, 61 IPs)

        Searchhead area (2*14)

            Searchhead cluster prod+ITSI (2*8)+1
            or
            Searchhead cluster prod  (2*5)+1
            Searchhead cluster ITSI (2*3)+1

            Searchhead cluster preprod (2*3)+1

            Searchhead cluster ES (2*1)+1

        Indexer area (2*20)

            Indexer prod (2*20)

        Supplemental area (2*12)?

            Heavy Forwarder prod (2*5)

            syslog (2*4)

            License Master + Deployment Server + Monitor Console  ("tool-ts") (1*1)

            Cluster Master (1*1)

            Monitoring? (2*1)

            <DNS? (2*1)>

            ... more splunk things?

    spare buffer subnet
        10.104.146.128/27 (usable 10.104.146.130 - 10.104.146.158, 29 IPs)
        10.104.146.160/27 (usable 10.104.146.162 - 10.104.146.190, 29 IPs)

        Prod and nonprod can extend into pieces of this buffer. I.e. prod from
        bottom and nonprod from top.

    nonprod subnet
        10.104.146.192/27 (usable 10.104.146.194 - 10.104.146.223, 29 IPs)
        10.104.146.224/27 (usable 10.104.146.226 - 10.104.146.254, 29 IPs)

        Searchhead area (2*2)

            Searchhead cluster test (2*2)

        Indexer area (2*5)

            Indexer test (2*5)

        Dev System Area (2*20)

        Supplemental area (2*5)

            Heavy Forwarder test (2*5)
