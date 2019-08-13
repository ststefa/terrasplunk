# Security group resources have been moved to shared/ in order to minimize
# redundancy and to minimize the amount of manually passed parameters in
# stages/*/. The different ecs modules will gather the required secgroup
# settings from shared using remote state.
# On the downside this has the effect that all instances of the full tenant
# share the same security group resources. While this should be ok it still
# means that a modification to a secgroup cannot be tested e.g. on the test
# stage before going to prod. It can only be tested on the test tenant
# (affecting the full tenant). If this causes problems in future then the
# secgroup resources should be pulled back from shared/ to modules/core/

# see https://docs.splunk.com/Documentation/Splunk/latest/InheritedDeployment/Ports

#All components, Management / REST API
#    outbound: N/A
#    inbound:  TCP/8089
#Search head / Indexer, Splunk Web access
#    outbound: Any
#    inbound:  TCP/8000
#Search head, App Key Value Store
#    outbound: Any
#    inbound:  TCP/8065, TCP/8191
#Indexer, Receiving data from forwarders
#    outbound: N/A
#    inbound:  TCP/9997
#Indexer, Receiving data from forwarders (ssl)
#    outbound: N/A
#    inbound:  TCP/9998
#Indexer cluster peer node / Search head cluster member, Cluster replication
#    outbound: N/A
#    inbound:  TCP/9887
#Indexer/Forwarder, Network input (syslog)
#    outbound: N/A
#    inbound:  UDP/514, TCP/6514

resource "opentelekomcloud_compute_secgroup_v2" "base-secgrp" {
  name        = "${local.project}-base-secgrp"
  description = "Base rules for all ${local.project} compute instances"

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    self        = true
  }

  # allow inbound ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # allow icmp
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "indexer-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-indexer-secgrp"
  description = "${local.project} indexer ports"

  # indexr port
  rule {
    from_port   = 9997
    to_port     = 9998
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

}

resource "opentelekomcloud_compute_secgroup_v2" "searchhead-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-searchhead-secgrp"
  description = " ${local.project} searchhead ports"

  # search gui
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # api
  rule {
    from_port   = 8089
    to_port     = 8089
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "parser-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-parser-secgrp"
  description = "${local.project} parser ports"

  # syslog udp
  rule {
    from_port   = 514
    to_port     = 514
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  # syslog tcp/tls
  rule {
    from_port   = 6514
    to_port     = 6514
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
