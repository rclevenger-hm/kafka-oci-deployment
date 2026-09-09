# Kafka rolling upgrade runbook

This runbook defines a conservative rolling-upgrade procedure for the OCI reference architecture. It is intentionally evidence-oriented: a version change is not considered successful merely because every process restarted.

## Preconditions

- Confirm the target Kafka/JDK combination is supported by the chosen release.
- Read the upstream Kafka upgrade notes for the exact source and target versions.
- Verify controller quorum is healthy and stable.
- Verify `offline partitions == 0` and investigate sustained under-replicated partitions before starting.
- Confirm disk/network headroom is sufficient for replica catch-up.
- Confirm a recent configuration backup/export exists.
- Record current broker/controller versions, cluster ID, topic/partition counts, and critical consumer lag.
- Freeze unrelated infrastructure/configuration changes for the duration of the exercise.

## Abort conditions

Stop the rollout if any of these appear and do not clear inside the agreed recovery window:

- controller quorum instability;
- offline partitions;
- material produce/fetch error increase;
- critical consumer lag breaching its SLO;
- replica recovery saturating disk/network capacity;
- unexpected client protocol incompatibility;
- repeated failure of an upgraded node to rejoin cleanly.

## Controller order

For dedicated KRaft controllers, change one voter at a time. After each restart:

1. wait for the process to become healthy;
2. confirm the controller is present in quorum status;
3. confirm the leader/quorum is stable;
4. observe for a full monitoring interval before continuing.

Never intentionally remove quorum by restarting multiple voting members together.

## Broker order

Upgrade one broker at a time.

For each broker:

1. Confirm no existing cluster-health abort condition is active.
2. If supported by the operating model, reduce avoidable leadership on the broker before maintenance.
3. Stop the broker cleanly.
4. Apply the version/runtime/configuration change.
5. Start the broker and verify process/service health.
6. Confirm it rejoins the cluster and its replicas return to ISR.
7. Wait for under-replicated partitions attributable to that broker to recover.
8. Check client error rate, request latency, throughput, disk/network pressure, and critical consumer lag.
9. Record elapsed recovery time before moving to the next broker.

Do not continue simply because a fixed timer elapsed; continue when the cluster has returned to the defined healthy envelope.

## Compatibility controls

Where Kafka requires staged protocol or metadata-version changes, keep compatibility settings at the older level until all nodes are running the new binary and cluster health has been revalidated. Only then schedule the irreversible/forward-only compatibility step as a separate reviewed change.

Treat feature-level or metadata-version advancement as a distinct release gate because it may reduce rollback options.

## Validation after the last node

- quorum stable;
- all expected brokers registered;
- offline partitions remain zero;
- under-replicated partitions returned to baseline;
- representative producer/consumer smoke test succeeds;
- critical consumer groups are within lag SLO;
- request latency/error metrics are comparable to pre-upgrade baseline;
- no unexpected authentication/TLS/client compatibility failures;
- restart and recovery times are recorded for future capacity planning.

## Rollback

A binary rollback is only safe while the cluster metadata/protocol state remains compatible with the previous version. Before any rollout, document that compatibility boundary from the exact upstream release notes.

If a single upgraded broker fails before any forward-only compatibility step:

1. stop that broker;
2. restore the last known-good package/runtime/configuration;
3. restart it;
4. wait for full ISR recovery;
5. verify clients and cluster health before deciding whether to resume.

If compatibility metadata has already advanced and downgrade is not supported, stop and treat recovery as an incident/change-plan problem rather than improvising a downgrade.

## Evidence to retain

For each exercise capture source/target versions, node order, health snapshots, recovery time per node, maximum under-replication, maximum critical consumer lag, any aborts, and follow-up capacity/configuration changes. Repeated upgrade exercises should become measured evidence for maintenance-window sizing rather than a checklist performed from memory.
