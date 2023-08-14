provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_core_instance" "kafka_broker" {
  count               = 3  # Deploying 3 broker nodes
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = "VM.Standard2.1"
  display_name        = "kafka-broker-${count.index}"

  source_details {
    source_type = "image"
    source_id   = var.kafka_image_id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("path_to_startup_script.sh"))
  }
}

resource "oci_core_instance" "zookeeper" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = "VM.Standard2.1"
  display_name        = "zookeeper"

  source_details {
    source_type = "image"
    source_id   = var.zookeeper_image_id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("path_to_zookeeper_startup_script.sh"))
  }
}

resource "oci_core_instance" "kafka_manager" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = "VM.Standard2.1"
  display_name        = "kafka-manager"

  source_details {
    source_type = "image"
    source_id   = var.kafka_manager_image_id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("path_to_kafka_manager_startup_script.sh"))
  }
}

resource "oci_core_instance" "schema_registry" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = "VM.Standard2.1"
  display_name        = "schema-registry"

  source_details {
    source_type = "image"
    source_id   = var.schema_registry_image_id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("path_to_schema_registry_startup_script.sh"))
  }
}