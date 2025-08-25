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
#HEC Indexer, Receiving data from HTTP (ssl)
#    outbound: N/A
#    inbound:  TCP/8088
#Indexer cluster peer node / Search head cluster member, Cluster replication
#    outbound: N/A
#    inbound:  TCP/9887
#Indexer/Forwarder, Network input (syslog)
#    outbound: N/A
#    inbound:  UDP/514, TCP/6514

resource "opentelekomcloud_compute_secgroup_v2" "base-secgrp" {
  name        = "${local.project}-base-secgrp"
  description = "Base rules for all ${local.project} compute instances"

  # allow free communication among all our splunk ecs instances in the tenant
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

  # allow node exporter scraping inside rz network
  rule {
    from_port   = 9100
    to_port     = 9100
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
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
  name        = "${local.project}-indexer-secgrp"
  description = "Specific rules for ${local.project} indexer instances"

  # indexer port
  rule {
    from_port   = 9997
    to_port     = 9997
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # indexer port SSL
  rule {
    from_port   = 9998
    to_port     = 9998
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Temporal hack! It needs to be remove by end of December 2020, see:
# https://issues.foo.ch/browse/MON-1924?focusedCommentId=23068574&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-23068574
#
# API access for SH1, 172.17.19.133 and 172.17.19.134, requested on Issues:
# https://issues.foo.ch/browse/MON-1586
# https://issues.foo.ch/browse/MON-1924
resource "opentelekomcloud_compute_secgroup_v2" "rest4someip-secgrp" {
  name        = "${local.project}-rest4someip-secgrp"
  description = "Specific rules for accessing P0 ${local.project} indexer instances from Security SH"

  rule {
    from_port   = 8089
    to_port     = 8089
    ip_protocol = "tcp"
    cidr        = "172.17.19.133/32"
  }

  rule {
    from_port   = 8089
    to_port     = 8089
    ip_protocol = "tcp"
    cidr        = "172.17.19.134/32"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "hec-secgrp" {
  name        = "${local.project}-hec-secgrp"
  description = "Specific rules for ${local.project} HEC (HTTPS) input"

  # HEC Indexer, Receiving data from HTTP (ssl)
  rule {
    from_port   = 8088
    to_port     = 8088
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }
}

# TODO: this resource is to be replaced by the more modular webgui/rest groups. Remove once all instances are reconfigured to use these
resource "opentelekomcloud_compute_secgroup_v2" "searchhead-secgrp" {
  name        = "${local.project}-searchhead-secgrp"
  description = "Specific rules for ${local.project} searchhead instances"

  # search gui (only from within RZ net)
  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }

  # api
  rule {
    from_port   = 8089
    to_port     = 8089
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "webgui-secgrp" {
  name        = "${local.project}-webgui-secgrp"
  description = "Enable access to ${local.project} webgui"

  # Splunk web GUI (only from within RZ net)
  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "rest-secgrp" {
  name        = "${local.project}-rest-secgrp"
  description = "Enable access to ${local.project} REST API"

  # Splunk REST API (only from within RZ net)
  rule {
    from_port   = 8089
    to_port     = 8089
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "webhook-secgrp" {
  name        = "${local.project}-webhook-secgrp"
  description = "Enable access to ${local.project} webhook for deployment-server concept"

  # Splunk REST API (only from within RZ net)
  rule {
    from_port   = 7003
    to_port     = 7003
    ip_protocol = "tcp"
    # maybe access needs to be more limited. As of 2020-06-23 the bitbucket
    # server had ip 10.171.161.30. Leaving open for now for maximum flexibility
    cidr = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "parser-secgrp" {
  name        = "${local.project}-parser-secgrp"
  description = "Specific rules for ${local.project} parser instances (sy, hf)"

  # syslog udp
  rule {
    from_port   = 514
    to_port     = 514
    ip_protocol = "udp"
    cidr        = "10.104.0.0/16"
  }

  # syslog tcp/tls
  rule {
    from_port   = 6514
    to_port     = 6514
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }

  # allow inbound rsyslog exporter scraping inside rz network
  rule {
    from_port   = 9101
    to_port     = 9101
    ip_protocol = "tcp"
    cidr        = "10.104.0.0/16"
  }
}
