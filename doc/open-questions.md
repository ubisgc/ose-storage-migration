# Open Questions: PVC Storage Migration to HNAS

## Purpose
These questions require human decisions or additional information before the design can be finalized and implementation can begin. Questions are grouped by category and prioritized.

---

## Strategic Decisions

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **S1** | Should we conduct a full discovery phase before finalizing the design, or proceed with assumptions and validate in parallel? | Project lead | Timeline and risk posture | Design finalization |
| **S2** | What is the target completion date for all namespace migrations? | Management | Phasing and resource allocation | Implementation planning |
| **S3** | What resources (people, time, test environment, HNAS capacity) are allocated to this project? | Management | Project scope and feasibility | All phases |
| **S4** | Is the operational complexity of a hybrid approach acceptable, or should we standardize on a single strategy (accepting higher downtime for some workloads)? | Operations + stakeholders | Automation complexity, risk profile | Strategy selection |
| **S5** | What is the rollback policy: rollback on any failure, or only on critical failures (accepting minor issues)? | Operations + app owners | Validation gates, automation design | Validation framework |

---

## Environment and Infrastructure

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **E1** | What are the HNAS StorageClass parameters: block (iSCSI/FC) or file (NFS), supported access modes, reclaim policy, performance tier? | Storage team | Strategy feasibility, copy tool selection | Discovery phase |
| **E2** | What existing StorageClasses and CSI drivers are currently configured in the cluster? | Platform team | Compatibility assessment | Discovery phase |
| **E3** | How many namespaces require migration, and what is the total PVC data volume (GB/TB scale)? | Platform team | Timeline, capacity planning | Discovery phase |
| **E4** | Does the cluster have VolumeSnapshot CRDs installed, and do source/target CSI drivers support snapshots? | Platform team | Snapshot strategy feasibility | Discovery phase |
| **E5** | What Kubernetes/OpenShift version is running, and what is the upgrade/patch schedule? | Platform team | Feature availability, compatibility | Discovery phase |

---

## Application and Workload

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **A1** | What is the acceptable downtime per application (none, minutes, hours)? | Application owners | Strategy selection per namespace | Strategy selection |
| **A2** | Which applications have documented quiescing procedures (graceful shutdown/startup)? | Application teams | Migration safety | Pre-migration |
| **A3** | Are there any databases or stateful applications with built-in replication that could be leveraged? | Application teams | Phased migration strategy | Strategy selection |
| **A4** | Are any PVCs shared across namespaces (mounted by pods in multiple namespaces)? | Platform team | Special handling required | Discovery phase |
| **A5** | What workload types exist per namespace (Deployments, StatefulSets, DaemonSets, Jobs)? | Platform team | Strategy selection per namespace | Discovery phase |

---

## Backup and Recovery

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **B1** | Does Velero or equivalent backup infrastructure exist in the cluster? | Operations | Backup-restore strategy feasibility | Strategy selection |
| **B2** | Are recent backups available for all namespaces, and are they verified restorable? | Operations | Rollback capability | Pre-migration |
| **B3** | What is the backup storage capacity available for temporary migration data? | Operations | Backup-restore feasibility | Discovery phase |

---

## Automation and Tooling

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **T1** | Can both source and target PVCs be mounted simultaneously in the same pod? (Requires testing) | Platform team | Direct copy strategy feasibility | PoC phase |
| **T2** | What copy tools (rsync, rclone, etc.) are available or can be installed in the cluster? | Platform team | Copy mechanism selection | PoC phase |
| **T3** | Does the Ansible service account have the required RBAC permissions for all migration operations? | Security + Platform | Automation execution | Discovery phase |
| **T4** | What SCC (Security Context Constraints) are required for migration pods, and are they permitted? | Security team | Pod configuration | Discovery phase |

---

## Operations and Process

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **O1** | What is the change management process for production migrations (approvals, windows, documentation)? | Operations | Workflow integration | Implementation planning |
| **O2** | What monitoring and alerting is in place, and can it be extended for migration tracking? | Operations | Visibility during migration | Implementation planning |
| **O3** | What are the escalation paths and on-call contacts during migration execution? | Operations | Incident response | Pre-migration |
| **O4** | Is there a test/staging environment representative of production for PoC testing? | Platform team | Validation capability | PoC phase |
| **O5** | What is the acceptable stability period after migration before decommissioning old PVCs (24h, 7d, 30d)? | Operations + app owners | Cleanup timing, rollback window | Post-migration |

---

## Risk and Compliance

| ID | Question | Decision Owner | Impact | Blocks |
|----|----------|----------------|--------|--------|
| **R1** | Are there compliance or audit requirements that affect migration procedures or evidence capture? | Compliance/Security | Validation framework, documentation | Design finalization |
| **R2** | What is the maximum acceptable risk level for different workload tiers (dev, staging, prod-critical)? | Stakeholders | Strategy selection, validation depth | Strategy selection |
| **R3** | Is there a disaster recovery plan that covers storage migration failures? | Operations | Rollback and recovery design | Design finalization |

---

## Questions Requiring Answers Before Discovery Phase

These must be answered to begin the discovery phase:

1. **S1** – Discovery timing decision
2. **S3** – Resource allocation
3. **E1** – HNAS StorageClass parameters (or access to storage team)
4. **O4** – Test environment availability

## Questions Requiring Answers Before PoC

These must be answered to begin proof-of-concept testing:

1. **E2** – Existing StorageClasses and CSI drivers
2. **T2** – Available copy tools
3. **T3** – Ansible RBAC permissions
4. **T4** – SCC constraints

## Questions Requiring Answers Before Pilot

These must be answered before migrating the first production namespace:

1. **A1** – Downtime tolerance per application
2. **A2** – Quiescing procedures
3. **B1/B2** – Backup infrastructure status
4. **O1** – Change management process
5. **O3** – Escalation paths

---

**Document Status**: Review-Ready  
**Date**: 2026-03-22  
**Next Step**: Human review to assign owners and prioritize answers.
