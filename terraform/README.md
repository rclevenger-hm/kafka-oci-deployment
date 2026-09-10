# Terraform network foundation

This directory is the first executable infrastructure slice for the Kafka-on-OCI reference architecture. It intentionally provisions **network primitives only**: a private VCN, a private subnet, and a network security group with an explicitly scoped Kafka client-listener rule.

It does not provision compute instances, Kafka binaries, KRaft voters, storage volumes, DNS records, bastion access, monitoring, or production routing. Those remain separate milestones so each reliability boundary can be reviewed and tested independently.

## Safety defaults

- Kafka nodes are placed in a subnet that prohibits public IPs.
- `allowed_client_cidrs` defaults to an empty set, so the Kafka client listener has no inbound CIDR rule until an operator explicitly supplies one.
- The NSG exposes only `kafka_client_port` for configured client CIDRs. Controller/inter-broker rules are deliberately deferred until the node-role topology is implemented.
- No Internet Gateway, NAT Gateway, Service Gateway, or default route is created here. The egress NSG rule does not itself create external reachability; routing remains an explicit later decision.
- Provider and Terraform versions are pinned/bounded in source rather than relying on an operator workstation default.

## Example plan

Create a local `terraform.tfvars` that is never committed:

```hcl
region         = "us-phoenix-1"
compartment_id = "ocid1.compartment.oc1..example"
name_prefix    = "kafka-lab"

allowed_client_cidrs = [
  "10.20.0.0/24",
]
```

Then inspect formatting and the dependency graph before any apply:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Do not apply this example unchanged to a production tenancy. CIDRs, connectivity, routing, DNS, authentication, availability-domain placement, and access paths must be designed for the target environment.

## Next infrastructure slice

The next reviewable step should define Kafka node roles and their **inter-node** network contract before adding instances. That work should make KRaft controller traffic, broker replication traffic, administrative access, and client traffic independently visible rather than opening a broad internal port range.
