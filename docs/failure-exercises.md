# Kafka on OCI — Failure Exercise Plan

This document turns the architecture's failure scenarios into repeatable operational exercises. It is intentionally written as a validation plan rather than a claim that the current repository can execute these drills automatically. Commands and identifiers must be adapted to the eventual Terraform/provisioning implementation.

## Exercise rules

Before every drill:

- run only in an isolated lab or explicitly approved non-production environment;
- confirm cluster health and record the baseline broker/controller membership;
- confirm offline partitions = 0 and under-replicated partitions = 0 unless the drill explicitly starts from a degraded state;
- start a small producer/consumer workload with a measurable success/error rate;
- capture dashboards/logs before introducing failure;
- define a stop condition and a recovery owner;
- change one failure variable at a time.

A drill is successful only when both **technical recovery** and **operator observability** are demonstrated. Surviving a failure that operators cannot diagnose is not production readiness.

## Evidence to capture for every drill

| Evidence | Why it matters |
| --- | --- |
| Failure start / detection / mitigation / recovery timestamps | Establishes MTTD and MTTR from evidence rather than memory. |
| Broker and controller membership before/during/after | Confirms the expected failure domain actually changed. |
| Offline and under-replicated partition counts | Shows availability and replication impact. |
| Producer errors/latency and consumer lag | Connects platform symptoms to client impact. |
| Controller/quorum state | Detects metadata-plane instability. |
| Disk/network/CPU pressure | Shows whether recovery itself creates a second incident. |
| Alerts fired and operator actions | Validates monitoring and runbook usefulness. |
| Post-recovery smoke test | Confirms the cluster is usable, not merely process-up. |

## Drill 1 — single broker process loss

**Purpose:** verify leader movement, replica behavior, alerting, and client retry behavior when one Kafka process disappears but the OCI instance remains available.

**Inject**

1. Select one broker that is not hosting the only valid replica of any intentionally under-replicated test topic.
2. Stop the Kafka service on that broker through the normal service manager.
3. Do not restart any other broker.

**Expected signals**

- broker unavailable alert;
- temporary under-replication while leadership/ISR converges;
- no offline partitions for correctly replicated test topics;
- client retries may increase, but sustained produce/consume availability should remain inside the lab objective;
- controller quorum remains stable.

**Recovery**

1. Start the broker service.
2. Wait for broker registration and replica catch-up.
3. Confirm under-replicated partitions return to zero.
4. Confirm producer/consumer error rates and latency return to baseline.

**Fail the drill if**

- a replicated test topic becomes unavailable;
- operators cannot identify the failed broker from telemetry;
- the broker is restarted before the cause/state is recorded;
- recovery saturates disk/network without a visible alert or capacity signal.

## Drill 2 — broker instance loss

**Purpose:** exercise the larger failure boundary where process, host networking, and attached runtime state disappear together.

**Inject**

- stop or terminate one lab broker instance using the approved OCI workflow;
- do not simulate this by only killing the Kafka process.

**Expected signals**

- OCI compute state and Kafka broker membership agree on the failed node;
- replicated topics remain available when the architecture assumptions are satisfied;
- recovery headroom is visible in disk/network metrics;
- replacement/recovery does not require broad public access or manual secret copying.

**Recovery acceptance**

- replacement/restored instance rejoins using the intended infrastructure/configuration path;
- advertised listeners and private DNS resolve correctly;
- replica catch-up completes;
- no temporary emergency configuration remains undocumented.

## Drill 3 — one KRaft controller loss

**Purpose:** prove that losing one controller does not remove metadata quorum and that operators recognize quorum degradation before attempting additional maintenance.

**Precondition:** use a three-member KRaft voting quorum.

**Inject**

- stop one controller process or controller-host instance in the lab.

**Expected signals**

- quorum retains a leader with two healthy voters;
- metadata operations continue;
- controller-unavailable/quorum-degraded telemetry fires;
- no operator proceeds with another controller restart while the quorum is degraded.

**Recovery acceptance**

- the controller rejoins;
- quorum voter state returns to expected membership;
- metadata propagation is normal before the drill is closed.

## Drill 4 — broker disk pressure

**Purpose:** validate time-to-full alerting and the operational response before Kafka can no longer append safely.

**Inject safely**

Use a dedicated lab volume or a bounded filler file outside Kafka-managed segment paths. Never delete Kafka log segments manually to manufacture recovery.

**Expected signals**

- warning threshold fires with enough response time to act;
- critical threshold is distinct from warning;
- time-to-full or growth-rate context is available;
- operators can identify the fastest-growing topic/partition set;
- no automated response silently deletes Kafka data.

**Recovery**

- remove only the synthetic filler or expand the lab volume through the intended storage workflow;
- verify append/replication behavior and client traffic normalize.

## Drill 5 — client DNS/connectivity failure

**Purpose:** distinguish client-path failures from broker failures.

**Inject**

Temporarily break name resolution or the client-to-broker NSG path for a dedicated lab client, not for the entire VCN.

**Expected signals**

- broker health remains normal;
- client connection errors increase;
- platform telemetry does not falsely report a broker outage;
- runbook triage directs the operator toward DNS/NSG/routing before broker restarts.

**Recovery acceptance**

- connectivity is restored without changing Kafka listener configuration;
- client metadata resolves to reachable private broker addresses.

## Drill 6 — certificate rotation failure

**Purpose:** prove a broken or partial rotation can be diagnosed without disabling TLS validation.

**Inject**

In a lab certificate set, intentionally leave one node or client with incompatible trust/certificate state during a documented rolling rotation.

**Expected signals**

- TLS handshake failures identify the affected path;
- hostname/SAN, expiry, and trust-chain state are inspectable;
- healthy nodes are not restarted indiscriminately;
- remediation restores compatible certificate state rather than weakening validation.

## Drill 7 — rolling restart under load

**Purpose:** verify maintenance guardrails and recovery headroom while client traffic continues.

For each broker:

1. verify offline partitions = 0;
2. verify under-replicated partitions = 0 or explicitly understood;
3. verify controller quorum is healthy;
4. restart one broker;
5. wait for registration and ISR recovery;
6. verify client error/latency signals;
7. only then continue.

The exercise fails if the procedure depends on fixed sleep intervals instead of observable recovery state.

## Drill 8 — replica rebuild under load

**Purpose:** determine whether planned spare disk/network capacity is enough for real recovery rather than steady state only.

Measure during rebuild:

- replication throughput;
- produce/fetch latency;
- disk service time;
- network utilization;
- consumer lag;
- estimated completion time.

The result should feed back into broker shape, volume, and operational-headroom decisions.

## Suggested scorecard

Record each exercise in a small table so architecture assumptions become reviewable evidence.

| Drill | Client impact | Detection time | Recovery time | Alert useful? | Runbook sufficient? | Capacity concern? | Follow-up |
| --- | --- | ---: | ---: | --- | --- | --- | --- |
| Broker process loss | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Broker instance loss | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Controller loss | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Disk pressure | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Client connectivity | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Certificate rotation | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Rolling restart | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Replica rebuild | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## Production-readiness gate

Do not mark an eventual deployment production-ready merely because these scenarios are documented. At minimum, the implementation should provide repeatable health checks and enough automation to run the core exercises against a disposable lab cluster. Results should be retained with the tested Kafka version, OCI topology, topic replication settings, workload profile, and date.

Related operational guidance: [`operations-runbook.md`](operations-runbook.md).
