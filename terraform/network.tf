locals {
  dns_prefix = substr(replace(var.name_prefix, "-", ""), 0, 12)
}

resource "oci_core_vcn" "kafka" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = local.dns_prefix
}

resource "oci_core_subnet" "kafka_private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.kafka.id
  cidr_block                 = var.kafka_subnet_cidr
  display_name               = "${var.name_prefix}-private"
  dns_label                  = "nodes"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_network_security_group" "kafka_nodes" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.kafka.id
  display_name   = "${var.name_prefix}-nodes"
}

resource "oci_core_network_security_group_security_rule" "client_ingress" {
  for_each                  = var.allowed_client_cidrs
  network_security_group_id = oci_core_network_security_group.kafka_nodes.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  description               = "Kafka client listener from an explicitly allowed CIDR"

  tcp_options {
    destination_port_range {
      min = var.kafka_client_port
      max = var.kafka_client_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_egress" {
  network_security_group_id = oci_core_network_security_group.kafka_nodes.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Outbound traffic; effective external reachability still depends on route-table design"
}
