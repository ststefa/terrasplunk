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
                10.104.146.194
                10.104.146.210

            Searchhead cluster preprod (2*1)
                10.104.146.195-196
                10.104.146.211-212
          
            Searchhead cluster ITSI (2*1)
                10.104.146.197
                10.104.146.213

            Searchhead cluster ES (2*1)
                10.104.146.198
                10.104.146.214

        Indexer area
        
            Indexer prod (2*2)
                10.104.146.199-200
                10.104.146.215-216

        Supplemental area
        
            Heavy Forwarder prod (2*1)
                10.104.146.201
                10.104.146.217
            
            syslog (2*1)
                10.104.146.202
                10.104.146.218


    nonprod subnet
        10.104.198.224/28 (usable 10.104.198.226 - 10.104.198.238, 13 IPs)
        10.104.198.240/28 (usable 10.104.198.242 - 10.104.198.254, 13 IPs)

        Searchhead area
        
            Searchhead cluster test (2*1)
                10.104.198.226
                10.104.198.242

        Indexer area
        
            Indexer test (2*1)
                10.104.198.227
                10.104.198.243

        Dev System Area

        Supplemental area
        
            Heavy Forwarder test (2*1)
                10.104.198.228
                10.104.198.244



## Prod tenant

    prod subnet
        10.104.146.0/26 (usable 10.104.146.2 - 10.104.146.62, 61 IPs)
        10.104.146.64/26 (usable 10.104.146.66 - 10.104.146.126, 61 IPs)
    
        Searchhead area (max 2*15)
            10.104.146.2-16
            10.104.146.66-80
        
            Searchhead cluster prod (max 2*5)
                10.104.146.2-6
                10.104.146.66-70
          
            Searchhead cluster preprod (max 2*3)
                10.104.146.7-9
                10.104.146.71-73
          
            Searchhead cluster ITSI (max 2*3)
                10.104.146.10-12
                10.104.146.74-76
    
            Searchhead cluster ES (max 2*3)
                10.104.146.13-15
                10.104.146.77-79

        Indexer area (max 2*30)
            10.104.146.17-46
            10.104.146.81-110
        
            Indexer prod (max 2*20)
                10.104.146.17-36
                10.104.146.80-99

        Supplemental area (max 2*16)
            10.104.146.47-62
            10.104.146.111-126
        
            Heavy Forwarder prod (max 2*5)
                10.104.146.47-51
                10.104.146.114-118
            
            syslog (max 2*4)
                10.104.146.52-55
                10.104.146.119-122


    nonprod subnet
        10.104.146.128/27 (usable 10.104.146.130 - 10.104.146.158, 29 IPs)
        10.104.146.160/27 (usable 10.104.146.162 - 10.104.146.190, 29 IPs)

        Searchhead area (max 2*5)
            10.104.146.130-134
            10.104.146.162-166
        
            Searchhead cluster test (max 2*2)
                10.104.146.130-131
                10.104.146.162-163
              
        Indexer area (max 2*5)
            10.104.146.135-139
            10.104.146.167-171
        
            Indexer test (max 2*5)
                10.104.146.135-139
                10.104.146.167-171

        Dev System Area (max 2*10)
            10.104.146.140-149
            10.104.146.172-181

        Supplemental area (max 2*5)
            10.104.146.150-154
            10.104.146.182-186
        
            Heavy Forwarder test (max 2*4)
                10.104.146.150-153
                10.104.146.182-185
