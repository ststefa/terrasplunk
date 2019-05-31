This module is about creating and maintaining the splunk platform

It is the next evolutionary step after chwing on terraform for a while. See the splunkprod project for that.

There is a superb talk recorded on Hashiconf which elaborates on the phases of terraform code. See

https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments
https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s

# Provisioning

Terroform creates puppet hieradata files using local-exec provisioners. A provisioning scripts pushes
this to the puppetmaster and triggers puppet on the to-be-provisioned system. This scripts also takes care of 
initially installing

puppet on the target if required