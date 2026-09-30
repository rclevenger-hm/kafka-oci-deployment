# KRaft compute foundation

The current Terraform intentionally establishes the private OCI network boundary first. The next infrastructure slice should add Kafka compute without weakening that boundary. This document defines the target contract before resources are introduced.

## Topology

Use KRaft mode rather than ZooKeeper. Keep controller and broker responsibilities explicit even when a small lab deployment initially co-locates them.

A production-oriented reference shape is three fault-domain-aware nodes. Each node receives a private VNIC in the existing Kafka subnet and the Kafka NSG. Public IP assignment remains prohibited. Client ingress continues to be controlled only by `allowed_client_cidrs`.

## Listener contract

- client listener: configurable, currently defaulting to TCP 9092;
- controller listener: private-node traffic only;
- inter-broker listener: private-node traffic only;
- no controller or replication port may be opened to `0.0.0.0/0`;
- advertised listeners must use private DNS/IP values reachable from approved clients.

## Storage

Kafka data should be placed on dedicated durable block volumes rather than the boot volume. Volume size and performance tier should be explicit inputs. Replacement of a compute instance must not implicitly destroy an attached data volume unless the operator has selected an ephemeral mode.

## Placement and replacement

Spread nodes across available fault domains when the region exposes them. Terraform changes should use predictable instance naming and stable node identity inputs. Rolling replacement should preserve quorum: never replace more than one controller-capable node at a time in the three-node reference topology.

## Bootstrap

Cloud-init or an equivalent bootstrap layer should:

1. mount the data volume;
2. render Kafka configuration from Terraform-provided node metadata;
3. format storage only when no existing cluster metadata is present;
4. start Kafka under a supervised service;
5. emit enough startup diagnostics to distinguish network, storage, and quorum failures.

Secrets or OCI credentials must not be written into user-data or committed configuration.

## Validation gates

Before this slice is considered complete:

- `terraform fmt`, `terraform validate`, and existing Terraform tests pass;
- no public IP is assigned to Kafka nodes;
- NSG rules expose only the documented client CIDRs and private cluster traffic;
- node replacement behavior is documented and tested in a disposable environment;
- the README includes cost and teardown notes for compute and block volumes.
