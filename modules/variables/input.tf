# Requiring the workspace as an input is not technically necessary. It's done to make this more explicit in the hope it will improve readability.
variable "workspace" {
  description = "One of 'default' or 'production'"
}

variable "stage" {
  description = "One of 'spielwiese', 'dev', 'test', 'qa',  or 'production'"
}
