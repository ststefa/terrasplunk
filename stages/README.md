The `stages` directory contains several distinct parts of the infrastructure. The goal of this is to have distinct states (i.e. multiple `terraform.tfstate` files) to reduce the risk of catastrophic errors. To learn more on how a single state file easily leads to catastrophic errors please review the talk by Nicki Watt mentioned in the toplevel README.

# Tenants

We use two tenants, test and production.

Prod Tenant will be used for (and only for) all customer-facing components. Uptime 24/7.

Test Tenant will be used for (and only for) non-customer-facing components, tests and experimentation. Each stage on prod-tenant has an equivalent stage on test-tenant. Uptime as required, environments recycled frequently.

# Stages

##development stage

The **dev** splunk stage is used to produce an arbitrarary amount of development instances built similar to production but on a single VM.

contains...

used for...

##test stage

The **test** splunk stage is used for splunk application testing tasks such as
 
contains...
 - Searchhead cluster Test
 - Indexer Test
 - Heavy Forwarder Test
 - Dev-Systems
 
used for...
 - For development and testing of search apps, dashboards, ...
 - For testing changes at data injection (indexer, HF)  
 - For testing interfaces to surrounding systems
 - For the verification of critical changes (indexes.conf, limits.conf, authorize.conf, ...)


##integration stage

The **int** splunk stage is used for verifying changed configuration that has been performed on dev/test platforms before they can go to production

contains...
- Searchhead cluster pre-prod

used for...

##production stage

The **prod** line of the splunk production stage (searchhead and indexer clusters, maybe more).

contains...
- Searchhead cluster Prod
- Searchhead cluster ITSI
- Searchhead cluster ES
- Indexer Prod
- Heavy Forwarder Prod
- syslog

used for...

The **spielwiese-p** splunk stage is used for platform testing tasks such as installing new Splunk versions, using different OS Versions or other architectural IAC changes on the **OTC Prod tenant**


# Stage subnets and IP ranges

## Test tenant

    prod subnet
        10.104.198.192/28 (usable 10.104.198.194 - 10.104.198.206, 13 IPs)
        10.104.198.208/28 (usable 10.104.198.210 - 10.104.198.222, 13 IPs)
    
        Searchhead area
    
            Searchhead cluster prod (2*2)

            Searchhead cluster preprod (2*1)
          
            Searchhead cluster ITSI (2*1)

            Searchhead cluster ES (2*1)

        Indexer area
        
            Indexer prod (2*2)

        Supplemental area
        
            Heavy Forwarder prod (2*1)
            
            syslog (2*1)


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

    prod subnet
        10.104.146.0/26 (usable 10.104.146.2 - 10.104.146.62, 61 IPs)
        10.104.146.64/26 (usable 10.104.146.66 - 10.104.146.126, 61 IPs)

        Searchhead area (2*14)

            Searchhead cluster prod+ITSI (2*8)
            or
            Searchhead cluster prod  (2*5)
            Searchhead cluster ITSI (2*3)

            Searchhead cluster preprod (2*3)

            Searchhead cluster ES (2*3)

        Indexer area (2*20)

            Indexer prod (2*20)

        Supplemental area (2*12)?

            Heavy Forwarder prod (2*5)

            syslog (2*4)

            License Master + Deployment Server + Monitor Console  ("tool-ts") (1*1)

            Cluster Master (1*1)

            ... more splunk things?


    nonprod subnet
        10.104.146.128/27 (usable 10.104.146.130 - 10.104.146.158, 29 IPs)
        10.104.146.160/27 (usable 10.104.146.162 - 10.104.146.190, 29 IPs)

        Searchhead area (2*2)

            Searchhead cluster test (2*2)

        Indexer area (2*5)

            Indexer test (2*5)

        Dev System Area (2*20)

        Supplemental area (2*5)

            Heavy Forwarder test (2*5)

    not-so-splunk subnet
        10.104.146.128/27 (usable 10.104.146.130 - 10.104.146.158, 29 IPs)
        10.104.146.160/27 (usable 10.104.146.162 - 10.104.146.190, 29 IPs)

        Supplemental area (2*1)

            Monitoring? (2*1)

            <DNS? (2*1)>
