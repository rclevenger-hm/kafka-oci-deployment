output "vcn_id" {
  description = "OCID of the Kafka VCN."
  value       = oci_core_vcn.kafka.id
}

output "private_subnet_id" {
  description = "OCID of the private subnet intended for Kafka nodes."
  value       = oci_core_subnet.kafka_private.id
}

output "kafka_node_nsg_id" {
  description = "OCID of the network security group intended for Kafka nodes."
  value       = oci_core_network_security_group.kafka_nodes.id
}
