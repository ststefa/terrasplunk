The `stages` directory contains several distinct parts of the infrastructure. The goal of this is to have distinct states (i.e. multiple `terraform.tfstate` files) to reduce the risk of catastrophic errors. To learn more on how a single state file easily leads to catastrophic errors please review the talk by Nicki Watt mentioned in the top-level README.

# Tenants
We use two tenants, test and production.

The production tenant will be used for (and only for) all customer-facing components with uptime 24/7.

The test tenant will be used for (and only for) non-customer-facing components, tests and experimentation. Each stage on the prod-tenant has an equivalent stage on test-tenant. Everything on the test tenant has a collaborative best-effort uptime. Environments will be completely recycled frequently.

# Stages

The **d0 aka dev** stage is used to produce multiple development instances built similar to production but on a single VM each.

The **t0 aka test** stage is used for splunk application testing tasks such as

 - Data onboarding
 - Development and testing of search apps, dashboards, ...
 - Testing data injection (indexer, HF)
 - Testing interfaces to surrounding systems
 - Verification of critical changes (indexes.conf, limits.conf, authorize.conf, ...)

>The t0 stage is
The **p0 aka prod** stage is used for ingesting all data from all sources (reagardless of the sources stage).

The **w0 aka spielwiese/pg** stage is used for platform testing tasks such as installing new Splunk versions, using different OS Versions or other architectural IAC changes and to develop deployment automation code
