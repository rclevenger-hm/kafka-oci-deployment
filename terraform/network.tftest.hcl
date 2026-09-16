mock_provider "oci" {}

run "private_network_defaults" {
  command = plan

  variables {
    region         = "us-ashburn-1"
    compartment_id = "ocid1.compartment.oc1..portfolio"
  }

  assert {
    condition     = oci_core_subnet.kafka_private.prohibit_public_ip_on_vnic
    error_message = "Kafka subnet must continue to prohibit public IPs."
  }

  assert {
    condition     = length(oci_core_network_security_group_security_rule.client_ingress) == 0
    error_message = "Kafka client ingress must remain closed by default."
  }

  assert {
    condition     = oci_core_network_security_group_security_rule.node_egress.direction == "EGRESS" && oci_core_network_security_group_security_rule.node_egress.protocol == "all"
    error_message = "The documented node egress rule changed unexpectedly."
  }
}

run "explicit_client_allowlist" {
  command = plan

  variables {
    region               = "us-ashburn-1"
    compartment_id       = "ocid1.compartment.oc1..portfolio"
    allowed_client_cidrs = ["10.60.0.0/24"]
    kafka_client_port    = 9094
  }

  assert {
    condition     = oci_core_network_security_group_security_rule.client_ingress["10.60.0.0/24"].source == "10.60.0.0/24"
    error_message = "Explicit client CIDRs must map directly to ingress rules."
  }

  assert {
    condition     = oci_core_network_security_group_security_rule.client_ingress["10.60.0.0/24"].tcp_options[0].destination_port_range[0].min == 9094 && oci_core_network_security_group_security_rule.client_ingress["10.60.0.0/24"].tcp_options[0].destination_port_range[0].max == 9094
    error_message = "Kafka ingress must stay scoped to the configured client listener port."
  }
}
