# do not allow autorecover for indexers
#variable "autorecover" {
#  default = "false"
#}

variable "stage" {
  description = "The stage (p0, t0, ...)"
}
variable "role" {
  description = "The stage (ix, sh, ...)"
}
variable "number" {
  type        = number
  description = "Sequential number of the instance, starting with 0"
}
