The `modules` directory contains reusable infrastructure objects which can be used in all stages.

# `core`
Contains resources which are commonly used by all objects of a stage. Exactly one instance of the core module is instantiated in every stage. As a result there is e.g. a single security group for all indexer instances of each stage as opposed to every indexer instance instantiating it's own and redundantly identical security group. While this might seem acceptable in this example, nevertheless redundancy should always be avoided as a best practice.

# `genericecs`
Contains the definition for a single default instance as defined for splunk. Multiple instances of this module are instantiated on every stage. The module is parameterizable in several ways (see `input.tf`), more might be added. The values for these parameters should usually come from the `variables` module.

This module contains the "placement logic", i.e. the rules which define in which availability zone (AZ) the instance will be located. This logic is based on the VM name. Even names (e.g. splp0id**00**) are placed in AZ1, odd names (e.g. splp0id**01**) are placed in AZ2. AZ can intentionally *not* be passed as a parameter to guarantee strict rules for placement. A strict rule seem useful to have an intuitive overview of hte possible effects of an AZ outage.

The `genericecs` can be used directly in the stage definitions. If other types of instances (i.e. instances with specific hardware setup) are required then specific modules (like `indexer`) should be created.

# `indexer`
Contains the definition for a single indexer instance which is a basic instance with additional disks attached. It uses the `genericecs` module internally so that the same rules apply. Multiple instances of this module are instantiated on every stage.

# `variables`
Centralizes all parameters which differ between tenants and stages. It encapsulates both differentiation axes (*tenant axis* and *stage axis*). E.g. a "prod-tenant/prod-stage" VM may have a different flavor than a "prod-tenant/test-stage" VM may have a different flavor than a "test-tenant/prod-stage" VM.

Values in `variables` can be divided by any (or no) axes which is achieved by corresponding nesting of values. Use as appropriate.
