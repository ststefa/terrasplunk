# Requiring the workspace as an input is not technically necessary. We could as well use "terraform.workspace". It's done to make this more explicit in the hope it will improve readability.

variable "workspace" {
  description = "One of 'default' or 'production'"
}

variable "stage" {
  description = "Stage abbreviation, e.g. p0, w0,..."
}
