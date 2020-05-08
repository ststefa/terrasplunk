locals {
  project = "splunk"
}


# Security group resources have been moved to shared/. See there for reasoning.

# Nothing left here for now. Place resources/data here which are shared among a
# single stage in both tenants (but not among stages). In other words: This is
# the place for stage-specific (but not tenant-specific) resources and data
# blocks. Differences between stages can be encapsulated using the
# variables module just in the same way as in the other modules.
