# Kafka on OCI — Operations Runbook

This runbook is a starting point for triage and recovery exercises for the reference architecture in this repository. Commands and service names should be adapted to the eventual provisioning implementation before production use.

## First response

When a Kafka alert fires:

1. Confirm whether the symptom is client-facing, replication-related, controller-related, or capacity-related.
2. Check whether the event is isolated to one broker/fault domain or affects the cluster broadly.
3. Preserve availability and durability before attempting cleanup or optimization.
4. Avoid restarting multiple brokers/controllers at once unless the failure mode is understood.
5. Record timestamps, affected brokers/topics, and any recent deployment/configuration changes.

## Quick health questions

- Are all expected brokers registered?
- Is the KRaft quorum healthy and stable?
- Are any partitions offline?
- Are partitions under-replicated?
- Is ISR shrinking repeatedly?
- Is disk space or disk latency approaching a critical threshold?
- Are produce/fetch requests failing or timing out?
- Is the impact limited to one consumer group?
- Did DNS, TLS, NSG, routing, or certificate state change recently?

## Broker unavailable

### Check

- Compute instance state in OCI.
- Process/service state on the host.
- Disk mount availability and filesystem health.
- Network reachability between cluster members.
- Broker logs around the first failure timestamp.
- Controller metadata for the broker.

### Response

1. Do not restart healthy brokers.
2. Determine whether the instance, process, disk, or network path failed.
3. Verify remaining replicas satisfy the intended durability threshold.
4. Restore the failed broker or replace it through infrastructure automation.
5. Watch replica recovery and network/disk saturation.
6. Confirm under-replicated partitions return to zero.
7. Verify client error/latency rates normalize.

## Under-replicated partitions

Under-replication is a symptom; identify the cause before forcing reassignment.

Common causes:

- unavailable broker;
- slow disk;
- saturated network;
- replica recovery after restart;
- insufficient broker capacity;
- repeated process instability.

### Response

1. Identify which brokers host affected replicas.
2. Check broker health and resource saturation.
3. Confirm replication is progressing.
4. Avoid large partition moves while recovery is already saturating the cluster.
5. Escalate if ISR does not recover inside the expected operational window.

## Offline partitions

Treat offline partitions as an availability incident.

1. Identify affected topics/partitions and their replica assignments.
2. Determine which replicas are unavailable.
3. Restore a valid in-sync replica whenever possible.
4. Avoid unclean leader election unless data-loss implications are explicitly accepted.
5. Validate producers/consumers after leadership is restored.

## Controller / KRaft quorum instability

1. Confirm how many controllers are reachable.
2. Check controller logs for election churn, disk issues, TLS errors, or network failures.
3. Verify controller listener/DNS connectivity between quorum members.
4. Restore one failed member at a time.
5. Confirm a stable leader and normal metadata propagation before further maintenance.

Do not take additional controller members down while quorum is degraded.

## Disk pressure

Kafka disk exhaustion can quickly become an availability problem.

### At warning threshold

- identify fast-growing topics/partitions;
- verify retention configuration;
- estimate time-to-full;
- check partition skew;
- schedule capacity expansion or safe data-retention changes.

### At critical threshold

1. Stop nonessential maintenance/partition movement that increases I/O.
2. Preserve enough free space for Kafka to operate safely.
3. Expand the volume or reduce retention only through an understood, approved action.
4. Do not manually delete Kafka log-segment files behind the broker.
5. Validate replication and client traffic after capacity is restored.

## Consumer lag

Consumer lag is not automatically a broker incident.

Check:

- whether produce rate increased;
- consumer instance health;
- rebalance frequency;
- downstream dependency latency;
- partition count versus consumer concurrency;
- broker fetch latency/errors.

Escalate to the Kafka platform only when cluster behavior contributes to the lag or the workload exceeds planned capacity.

## TLS / certificate failure

Symptoms may include widespread connection failures despite otherwise healthy brokers.

1. Check certificate validity and chain.
2. Confirm hostname/SAN alignment with advertised listeners.
3. Verify truststore/keystore distribution.
4. Check whether a recent rotation left mixed certificate state.
5. Restore compatibility without disabling TLS validation as a shortcut.
6. Complete rotation through the documented rolling procedure.

## Rolling restart / upgrade guardrails

Before restarting each node:

- cluster is otherwise healthy;
- offline partitions = 0;
- under-replicated partitions = 0 or understood;
- quorum has sufficient healthy members;
- disk/network headroom is adequate for replica catch-up.

After each broker returns:

- wait for broker registration;
- wait for replicas/ISR to recover;
- confirm client error rate remains normal;
- only then continue to the next broker.

## Post-incident checklist

- [ ] Client-facing impact and duration recorded.
- [ ] Root trigger identified or narrowed to a testable hypothesis.
- [ ] Cluster health fully restored.
- [ ] Temporary mitigations removed or tracked.
- [ ] Capacity/security/configuration follow-up issues created.
- [ ] Alerts adjusted only if the incident demonstrated poor signal quality.
- [ ] Recovery time and operator steps compared with expected SLO/runbook assumptions.
- [ ] Reproducible failure test added when practical.

## Planned automation hooks

As implementation is added, this runbook should link directly to validated commands or scripts for:

- quorum status;
- broker registration;
- under-replicated/offline partition checks;
- topic/partition inventory;
- consumer-lag inspection;
- disk-capacity report;
- rolling-restart preflight;
- smoke producer/consumer test.

The goal is to make the common diagnostic path repeatable without hiding the underlying Kafka state from the operator.
