This module is about creating and maintaining the splunk platform

It is the next evolutionary step after cehwing on terraform for a while. See the splunkprod project for that.

There is a superb talk recorded on Hashiconf which elaborates on the phases of terraform code. See

https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments

which leads to

https://www.youtube.com/watch?v=wgzgVm7Sqlk&t=1s

While the `splunkprod` uses a *multi terralith* structure this project restructures it to a *terramod* setup.

# Provisioning

Once the base infrastructure has been created with terraform the next most important step is the provisioning. 
This turns the empty instances into real, working instances.

Multiple approaches how this can be done are available and it is 
currently not proven which one will be the best.

A key requirement is that certain data from terraform will need to be passed to the provisioning step, e.g. disk device 
names and instance names
. A good solution will have to use a generic mechanism which is capable of transferring arbitrary data to the 
provisioner.

The current approach uses terroform `local-exec` provisioners which create parameter files. Any resource can add to 
this parameter files. A separate provisioning 
scripts creates puppet hierdata from the parameter files, pushes this to the puppetmaster and triggers puppet on the 
to-be-provisioned system. This script also takes care of 
initially installing puppet on the target if required.