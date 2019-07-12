#cloud-config
hostname: ${hostname}
fqdn: ${fqdn}

packages:

runcmd:
 - systemctl stop firewalld
 - systemctl disable firewalld

