The `modules` directory contains reusable infrastructure objects which can be used in all stages.

# `core`
Contains resources which are commonly used by all objects of a stage. E.g. there is a single security group for indexers which is used by all indexer instances (as opposed to every idexer instance using it's own and redundantly identical security group).

# `genericecs`
Contains the definition for a single default instance as defined for splunk. It is parameterizable in several ways (see `input.tf`). More might be added. The values for these parameters should usually come from the `variables` module.

This module contains the "placement logic", i.e. the rules which define in which availability zone (AZ) the instance will be located. This logic is based on the VM name. Even names (e.g. splp0id**00**) are placed in AZ1, odd names (e.g. splp0id**01**) are placed in AZ2. This is not passed as a parameter to guarantee strict rules for placement.

# `indexer`
Contains the definition for a single indexer instance which is a basic instance with additional disks attached. It therefore uses the `genericecs` internally.

# `variables`
Centralizes all parameters which differ between tenants and stages. It encapsulates both differentiation axes (tenant axis and stage axis). E.g. a "prod-tenant/prod-stage" VM may have a different flavor than a "prod-tenant/test-stage" VM may have a different flavor than a "test-tenant/prod-stage" VM.

Values can be divided by any (or no) axes which is achieved by corresponding nesting of values. Use as appropriate.
