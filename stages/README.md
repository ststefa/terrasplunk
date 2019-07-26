The `stages` directory contains several distinct parts of the infrastructure. The goal of this is to have distinct states (i.e. multiple `terraform.tfstate` files) to reduce the risk of catastrophic errors. To learn more on how a single state file easily leads to catastrophic errors please review the talk by Nicki Watt mentioned in the top-level README.

# Tenants
We use two tenants, test and production.

Prod tenant will be used for (and only for) all customer-facing components with uptime 24/7.

Test Tenant will be used for (and only for) non-customer-facing components, tests and experimentation. Each stage on prod-tenant has an equivalent stage on test-tenant with uptime as required, environments recycled frequently.

# Stages
## development stage
The **dev** stage is used to produce multiple development instances built similar to production but on a single VM each.

contains...

used for...

## test stage
The **test** stage is used for splunk application testing tasks such as
 
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


## qa stage
The **qa** (quality assurance) stage is used for verifying changed configuration that has been performed on dev/test platforms before they can go to production

contains...
- Searchhead cluster pre-prod

used for...

## production stage
The **prod** line of the splunk production stage (searchhead and indexer clusters, maybe more).

contains...
- Searchhead cluster Prod
- Searchhead cluster ITSI
- Searchhead cluster ES
- Indexer Prod
- Heavy Forwarder Prod
- syslog

used for...

## spielwiese stage
The **spielwiese** stage is used for platform testing tasks such as installing new Splunk versions, using different OS Versions or other architectural IAC changes.



