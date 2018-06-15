/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_vpc_endpoint" "remote_metastores" {
  count              = "${length(var.remote_metastores)}"
  vpc_id             = "${var.vpc_id}"
  vpc_endpoint_type  = "Interface"
  service_name       = "${lookup(var.remote_metastores[count.index],"endpoint")}"
  subnet_ids         = ["${var.subnets}"]
  security_group_ids = ["${var.security_groups}"]
}

data "external" "endpoint_dnsnames" {
  count   = "${length(var.remote_metastores)}"
  program = ["bash", "${path.module}/scripts/endpoint_dns_name.sh", "${aws_vpc_endpoint.remote_metastores.*.id[count.index]}"]
}

data "template_file" "remote_metastores_yaml" {
  count    = "${length(var.remote_metastores)}"
  template = "${file("${path.module}/templates/waggle-dance-federation-remote.yml.tmpl")}"

  vars {
    prefix         = "${lookup(var.remote_metastores[count.index],"prefix")}"
    metastore_host = "${lookup(data.external.endpoint_dnsnames.*.result[count.index],"dnsname")}"
    metastore_port = "${lookup(var.remote_metastores[count.index],"port")}"
  }
}

data "template_file" "local_metastores_yaml" {
  count    = "${length(var.local_metastores)}"
  template = "${file("${path.module}/templates/waggle-dance-federation-local.yml.tmpl")}"

  vars {
    prefix         = "${lookup(var.local_metastores[count.index],"prefix")}"
    metastore_host = "${lookup(var.local_metastores[count.index],"host")}"
    metastore_port = "${lookup(var.local_metastores[count.index],"port")}"
  }
}
