The `modules` directory contains reusable infrastructure objects which can be used in terraform code to improve DRYness (https://de.wikipedia.org/wiki/Don’t_repeat_yourself). Modules do not have state but are instead instantiated.

# `core`
Contains resources which are commonly used by all objects of a stage. Exactly one instance of the core module is instantiated in every stage. As a result there is e.g. a single security group for all indexer instances of each stage as opposed to every indexer instance creating it's own and redundantly identical security group. While this example might seem a minor drawback, nevertheless redundancy should always be avoided as a best practice. The `core` module is the mechanism to achieve that in general.

The difference between the `core` module and the `shared` directory is that
- the `core` module has no state while the `shared` directory has
- resources of the `core` module are shared by all objects of a (tenant,stage) tuple while resources of the `shared` directory are shared by all objects of a tenant (regardless of stage)

# `genericecs`
Contains the definition for a single default instance as defined for splunk. Multiple instances of this module are instantiated on every stage. The module is parameterizable in several ways (see `input.tf`), more might be added. The values for these parameters should usually come from the `variables` module.

This module contains the "placement logic", i.e. the rules which define in which availability zone (AZ) the instance will be located. This logic is based on the VM name. Even names (e.g. splp0id**00**) are placed in AZ1, odd names (e.g. splp0id**01**) are placed in AZ2.

The AZ can intentionally *not* be passed as a parameter to guarantee strict rules for placement. Such rules seem a good idea, e.g. to have an intuitive overview of the possible effects of an AZ outage and to prevent human error when doing the VM placement. Algorithms just do a better job than humans when it comes to strictness.

The `genericecs` can be used directly in the stage definitions. If other types of instances (i.e. instances with specific hardware setup) are required then specific modules (just like `indexer`) should be created encapsulating these requirements.

# `indexer`
Contains the definition for a single indexer instance which is a basic instance with additional disks attached. It uses the `genericecs` module internally so that the same rules apply. Multiple instances of this module are instantiated on every stage.

# `variables`
Centralizes all parameters which differ between tenants and stages. It encapsulates both differentiation axes (*tenant axis* and *stage axis*). E.g. a "prod-tenant/prod-stage" VM may have a different flavor than a "prod-tenant/test-stage" VM may have a different flavor than a "test-tenant/prod-stage" VM.

Values in `variables` can be divided by any (or no) axes which is achieved by corresponding nesting of values. Use as appropriate.

By using this approach we can further detail differences between stages/tenants in a flexible way without having to change the rest of the terraform implementation.
