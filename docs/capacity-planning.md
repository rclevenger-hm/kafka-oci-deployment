# Capacity and recovery budget

This worksheet turns the reference architecture into explicit sizing assumptions. It is a planning aid, not a claim that the repository currently provisions or benchmarks a production Kafka cluster.

## 1. Record the workload envelope

Capture these inputs before choosing broker shapes or storage:

| Input | Symbol | Example question |
| --- | --- | --- |
| Peak producer payload rate | `P` | How many MiB/s arrive during the busiest sustained interval? |
| Replication factor | `R` | How many copies of each partition must be retained? |
| Retention period | `T` | How many hours/days of local log must remain available? |
| Broker count | `N` | How many brokers carry data? |
| Failure budget | `F` | How many brokers must the cluster tolerate losing while remaining serviceable? |
| Target utilization | `U` | What steady-state fraction of disk/network/CPU is acceptable? |
| Recovery objective | `RT` | How quickly must replicas regain healthy redundancy after a failure? |

Use observed peak rates where possible. If only averages exist, record the multiplier used to produce the peak assumption and validate it under load before production use.

## 2. Storage envelope

A first-order retained-data estimate is:

```text
retained_payload = peak_ingress_per_second × retention_seconds
replicated_payload = retained_payload × replication_factor
```

Do not size disks to `replicated_payload / N` alone. Reserve space for:

- uneven partition placement and hot topics;
- segment rollover and deletion lag;
- replica catch-up after broker replacement;
- compaction working space for compacted topics;
- operational logs and package/runtime overhead;
- the loss of `F` brokers without forcing surviving disks to saturation.

A conservative planning check is:

```text
usable_cluster_disk_after_failure = (N - F) × broker_disk × U
required_cluster_disk             = replicated_payload × placement_skew_factor

require usable_cluster_disk_after_failure > required_cluster_disk
```

`placement_skew_factor` should be greater than 1.0 and justified by measurements. The point is not the exact factor; it is to make skew an explicit assumption instead of assuming perfect balancing.

## 3. Network and replication budget

Replication makes broker traffic materially larger than producer ingress. At minimum, budget for:

- client produce traffic;
- follower replication traffic;
- consumer egress;
- inter-broker movement during reassignments or recovery;
- administration and observability traffic.

Normal operation must leave recovery bandwidth unused. If a single failed broker contains `D` bytes that must be copied within `RT` seconds, the recovery path needs approximately:

```text
required_recovery_throughput = D / RT
```

That bandwidth is in addition to live workload traffic. A cluster that is healthy only while every broker is present has no useful recovery budget.

## 4. Broker-loss headroom

For each critical resource, evaluate both normal and degraded states:

| Resource | Normal-state question | Failure-state question |
| --- | --- | --- |
| Disk | Is steady utilization below the target? | Can surviving brokers accept/rebuild replicas without exhausting disk? |
| Network | Is client + replication traffic bounded? | Is there enough spare throughput for replica recovery? |
| CPU | Are request handlers comfortably below saturation? | Can fewer brokers absorb client work plus recovery overhead? |
| File descriptors | Are partition/socket counts bounded? | Does reassignment or reconnect pressure remain within limits? |
| Heap/page cache | Are GC and cache behavior stable? | Does denser partition ownership remain stable after loss? |

Record the expected steady-state and broker-loss utilization instead of using a single capacity number.

## 5. Partition and quorum constraints

Capacity is not only bytes and throughput.

- Keep partition counts per broker within a tested operational envelope.
- Ensure replication factor does not exceed available brokers and still satisfies the intended failure tolerance.
- For KRaft, size the controller quorum independently from broker data capacity. Maintain an odd-numbered quorum and validate the intended controller-loss behavior.
- Verify `min.insync.replicas` and producer acknowledgement policy together. A durability setting that blocks all writes under the intended failure scenario is an availability choice and should be documented as such.
- Treat leader concentration as a capacity risk even when replica counts appear balanced.

## 6. Recovery-time validation

A recovery objective is credible only after measuring it. For each failure exercise, capture:

1. bytes of replica deficit introduced;
2. time until affected partitions regain the required ISR state;
3. peak network, disk, and CPU utilization during recovery;
4. client produce/fetch latency and error rate during recovery;
5. whether throttles were required to protect foreground traffic;
6. whether the cluster retained enough headroom for a second fault.

The exercises in [`failure-exercises.md`](failure-exercises.md) should produce this evidence rather than only confirming that a broker eventually rejoins.

## 7. Example planning worksheet

Use a table like this in an environment-specific design record:

| Item | Planned value | Evidence / source | Failure-state value | Pass condition |
| --- | ---: | --- | ---: | --- |
| Peak producer ingress | TBD | load test / observed workload | same | within broker/network budget |
| Consumer egress | TBD | load test / observed workload | same | within broker/network budget |
| Retained replicated bytes | TBD | rate × retention × RF | same | fits surviving disk at target utilization |
| Broker disk utilization | TBD | model + test | TBD | below chosen degraded-state ceiling |
| Broker network utilization | TBD | load test | TBD | leaves measured recovery bandwidth |
| Replica recovery throughput | TBD | failure exercise | TBD | restores redundancy within `RT` |
| Controller quorum | TBD | architecture | degraded quorum | retains required majority |

Avoid filling unknowns with optimistic defaults. `TBD` is safer than a number that has not been tied to a workload or experiment.

## 8. Release evidence checklist

Before describing an environment as production-ready, retain evidence that:

- peak and degraded-state workload tests were run against the chosen shapes;
- disk sizing includes retention, replication, skew, and broker-loss headroom;
- replica recovery meets the documented recovery objective while client traffic continues;
- controller and broker failure exercises match the intended fault tolerance;
- alerts exist for capacity exhaustion, under-replicated/offline partitions, ISR degradation, request latency, and recovery saturation;
- a scaling trigger and operator action are defined before resource utilization reaches the tested ceiling.

Capacity planning should be revisited when throughput, retention, replication policy, partition count, instance shape, or recovery objectives materially change.
