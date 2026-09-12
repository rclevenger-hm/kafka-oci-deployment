variable "region" {
  description = "OCI region where the Kafka network foundation is created."
  type        = string
}

variable "compartment_id" {
  description = "OCID of the compartment that will own the network resources."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix used for display names and DNS labels."
  type        = string
  default     = "kafka"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain 2-15 lowercase letters, digits, or hyphens."
  }
}

variable "vcn_cidr" {
  description = "CIDR for the private Kafka VCN."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block."
  }
}

variable "kafka_subnet_cidr" {
  description = "CIDR for the private Kafka node subnet."
  type        = string
  default     = "10.42.10.0/24"

  validation {
    condition     = can(cidrhost(var.kafka_subnet_cidr, 0))
    error_message = "kafka_subnet_cidr must be a valid CIDR block."
  }
}

variable "allowed_client_cidrs" {
  description = "CIDRs permitted to reach the Kafka client listener. Keep this list narrowly scoped."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_client_cidrs : can(cidrhost(cidr, 0))])
    error_message = "allowed_client_cidrs must contain only valid CIDR blocks."
  }

  validation {
    condition     = alltrue([for cidr in var.allowed_client_cidrs : !contains(["0.0.0.0/0", "::/0"], cidr)])
    error_message = "allowed_client_cidrs must not expose the Kafka listener to the entire internet."
  }
}

variable "kafka_client_port" {
  description = "TCP client listener port exposed by the Kafka node NSG."
  type        = number
  default     = 9092

  validation {
    condition     = var.kafka_client_port >= 1 && var.kafka_client_port <= 65535
    error_message = "kafka_client_port must be a valid TCP port."
  }
}
