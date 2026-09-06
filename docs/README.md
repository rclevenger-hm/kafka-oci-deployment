# Operations documentation

These documents support the reference architecture in the repository root. They describe intended operational behavior and validation criteria; they do not claim that the current repository contains a production-ready Kafka deployment.

- [`operations-runbook.md`](operations-runbook.md) — triage and recovery guidance for broker, quorum, replication, disk, lag, TLS, and rolling-maintenance incidents.
- [`failure-exercises.md`](failure-exercises.md) — controlled lab drills with preconditions, expected signals, recovery criteria, evidence capture, and a production-readiness scorecard.
- [`capacity-planning.md`](capacity-planning.md) — workload, retention, replication, broker-loss headroom, recovery-throughput, and release-evidence worksheet for turning architecture assumptions into measurable budgets.

As executable Terraform and provisioning are added, these documents should link to validated health-check, smoke-test, load-test, and failure-injection commands rather than duplicating command snippets that can drift from implementation.
