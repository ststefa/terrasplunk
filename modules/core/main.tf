locals {
  project = "splunk"
}


resource "opentelekomcloud_compute_secgroup_v2" "indexer-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-${var.stage}-indexer-secgrp"
  description = "${local.project}-${var.stage}-indexer-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # indexr port
  rule {
    from_port   = 9997
    to_port     = 9997
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "searchhead-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-${var.stage}-searchhead-secgrp"
  description = "${local.project}-${var.stage}-searchhead-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # search gui
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

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_secgroup_v2" "parser-secgrp" {
  # TODO: Extend/fix ports
  name        = "${local.project}-${var.stage}-parser-secgrp"
  description = "${local.project}-${var.stage}-parser-secgrp"

  # ssh
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

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

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}


