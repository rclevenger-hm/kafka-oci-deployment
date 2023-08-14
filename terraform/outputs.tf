output "kafka_broker_ips" {
  description = "Public IP addresses of the Kafka broker nodes"
  value       = [for instance in oci_core_instance.kafka_broker : instance.public_ip]
}

output "zookeeper_ip" {
  description = "Public IP address of the ZooKeeper node"
  value       = oci_core_instance.zookeeper.public_ip
}

output "kafka_manager_ip" {
  description = "Public IP address of the Kafka Manager (CMAK) node"
  value       = oci_core_instance.kafka_manager.public_ip
}

output "schema_registry_ip" {
  description = "Public IP address of the Schema Registry node"
  value       = oci_core_instance.schema_registry.public_ip
}
