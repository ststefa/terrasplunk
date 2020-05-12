# Splunk terraform stages

The `stages` directory contains several distinct parts of the infrastructure. The goal of this is to have distinct states (i.e. multiple `terraform.tfstate` files) to reduce the risk of catastrophic errors. To learn more on how a single state file easily leads to catastrophic errors please review the talk by Nicki Watt mentioned in the top-level README.

## Tenants

We use two tenants, test and production.

The production tenant will be used for (and only for) all customer-facing components with uptime 24/7.

The test tenant will be used for (and only for) non-customer-facing components, tests and experimentation. Each stage on the prod-tenant has an equivalent stage on test-tenant. Everything on the test tenant has a collaborative best-effort uptime. Environments will be completely recycled frequently.

## Stages

The **d0** (aka *dev*) stage is used to produce multiple development instances built similar to production but on a single VM each. This is not currently implemented.

The **g0** (aka *global*) stage is used for systems which are shared across stages. Currently this contains the splunk license master (lm) to whom all stages are connected to handle their licensing.

The **h0** (aka *history*) stage contains systems which are built as part of this platform but actually serve certain functions for use with the old splunk platform.

The **p0** (aka *prod*) stage is used for ingesting all data from all sources (regardless of the sources stage).

The **t0** (aka *test*) stage is used for splunk application testing tasks such as

- Data onboarding
- Development and testing of search apps, dashboards, ...
- Testing data injection (indexer, HF)
- Testing interfaces to surrounding systems
- Verification of critical changes (indexes.conf, limits.conf, authorize.conf, ...)

The **w0** (aka *spielwiese* or *pg*) stage is used for platform testing tasks such as installing new Splunk versions, using different OS versions or other fundamental IAC changes and to develop deployment automation code.
