# Decision Brief: PVC Storage Migration to HNAS

## Context
We have a reviewed design for migrating Kubernetes/OpenShift PVC-backed workloads namespace-by-namespace to a new HNAS StorageClass, using Ansible automation from a remote workstation.

Before we proceed to discovery and implementation, **7 strategic questions require decisions from stakeholders**.

---

## Decision Status Tracker

| ID | Question Summary | Owner | Status | Answer |
|----|------------------|-------|--------|--------|
| S1 | Discovery timing | Project lead | ✅ Decided | Discovery first, time-boxed |
| S2 | Target completion date | Management | ✅ Decided | 7 work days for tool stack |
| S3 | Resource allocation | Management | ✅ Decided | Kind local → test OpenShift |
| S4 | Hybrid vs single strategy | Ops + stakeholders | ✅ Decided | Hybrid (copy/backup) + Velero recovery |
| S5 | Rollback policy | Ops + app owners | ✅ Decided | Velero backup first, manual restore |
| A1 | Downtime tolerance | App owners | ✅ Decided | Smooth/fast; team handles per-app |
| R2 | Risk tolerance by tier | Stakeholders | ✅ Decided | Sandbox → test → prod |

---

## Questions Requiring Decisions

### S1: Discovery Timing

|                    |                                                                                                                                                                         |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Question**       | Should we conduct a full discovery phase before finalizing the design, or proceed with assumptions and validate in parallel?                                            |
| **Option A**       | Discovery first — validate all assumptions before building automation. Lower risk, slower start.                                                                        |
| **Option B**       | Parallel — start building while discovering. Faster start, higher risk of rework.                                                                                       |
| **Recommendation** | **Option A (Discovery first)**. Critical unknowns (HNAS capabilities, existing storage inventory, backup status) must be resolved before choosing migration strategies. |
| **Decides**        | Project lead                                                                                                                                                            |
| **Answer**         | Yes lets complet the discover phase before starting the design, but we must not bee stocked in this phase for ever                                                      |
| **Project owner** |                                                                                                                                                                         |
| **22-03-2026**     |                                                                                                                                                                         |

---

### S2: Target Completion Date

| |                                                                                                                                                |
|---|------------------------------------------------------------------------------------------------------------------------------------------------|
| **Question** | What is the target completion date for all namespace migrations?                                                                               |
| **Why it matters** | Drives phasing, resource allocation, and whether we can run sequential migrations or need parallelism.                                         |
| **Recommendation** | Define a realistic date after discovery reveals scope (namespace count, data volume).                                                          |
| **Decides** | Management                                                                                                                                     |
| **Answer** | Dont fokus one the migration time line only on the createsion of the tool stack for the migration, and we have 7 work days to provide the tool |
| **Project owner** |                                                                                                                                                |
| **22-03-2026** |                                                                                                                                                |

---

### S3: Resource Allocation

| |                                                                                                                                                                                             |
|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Question** | What resources (people, time, test environment, HNAS capacity) are allocated to this project?                                                                                               |
| **Why it matters** | Determines whether we can run a full PoC, whether test environment exists, and whether we have HNAS capacity for all namespaces.                                                            |
| **Recommendation** | Allocate at minimum: 1 platform engineer, 1 test namespace, HNAS capacity for test + pilot namespaces.                                                                                      |
| **Decides** | Management                                                                                                                                                                                  |
| **Answer** | The team must test on som kind og local test system, like a Kind setup where the tool can betested in som kind of integration test, after that it can bee teste in a test Openshift cluster |
| **Project owner** |                                                                                                                                                                                             |
| **22-03-2026** |                                                                                                                                                                                             |

---

### S4: Hybrid vs Single Strategy

| |                                                                                                                                                                                   |
|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Question** | Is the operational complexity of a hybrid approach acceptable, or should we standardize on a single strategy?                                                                     |
| **Option A** | Hybrid — select strategy per workload type (blue-green for stateless, backup-restore for large data, direct copy for small data). Optimal downtime, higher automation complexity. |
| **Option B** | Single strategy — use backup-restore for all workloads. Simpler automation, higher downtime for some workloads.                                                                   |
| **Recommendation** | **Option A (Hybrid)**. Workloads vary significantly; a single strategy forces unnecessary downtime on stateless apps or risks data loss on large stateful apps.                   |
| **Decides** | Operations + stakeholders                                                                                                                                                         |
| **Answer** | A hybrid approch where the recovery after a failed migraction is done using , the migration it selv can de dones a copy or backup/restore.               |
| **Project owner** |                                                                                                                                                                                   |
| **22-03-2026** |                                                                                                                                                                                   |

---

### S5: Rollback Policy

| |                                                                                                                                                        |
|---|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Question** | What is the rollback policy: rollback on any failure, or only on critical failures?                                                                    |
| **Option A** | Rollback on any failure — safest posture. Any validation failure triggers rollback.                                                                    |
| **Option B** | Rollback only on critical failures — minor issues (e.g., non-critical log errors) are documented and accepted.                                         |
| **Recommendation** | **Option A (Rollback on any failure)** for first migrations. Can relax policy after process is proven.                                                 |
| **Decides** | Operations + application owners                                                                                                                        |
| **Answer** | Velero backup and restore, so the tool must take a Velero backup before as firste step in the migration, the restore if migration failes can be manually |
| *Project owner** |                                                                                                                                                        |
| **22-03-2026** |                                                                                                                                                        |

---

### A1: Downtime Tolerance

| | |
|---|---|
| **Question** | What is the acceptable downtime per application (none, minutes, hours)? |
| **Why it matters** | Drives strategy selection per namespace. Stateless apps may tolerate only seconds; batch jobs may tolerate hours. |
| **Recommendation** | Classify applications into tiers (e.g., Tier 1: <5 min, Tier 2: <1 hour, Tier 3: maintenance window OK). Map tiers to migration strategies. |
| **Decides** | Application owners |
| **Answer** | It depends on the individual system, but this is taken care of by the team that performs the migration, you just need to deliver a tool stack that will make it as smooth and fast as possible. |
| **Project owner** | |
| **22-03-2026** | |

---

### R2: Risk Tolerance by Tier

| | |
|---|---|
| **Question** | What is the maximum acceptable risk level for different workload tiers (dev, staging, prod-critical)? |
| **Why it matters** | Determines validation depth and whether we can use riskier (faster) strategies for some workloads. |
| **Recommendation** | Conservative for prod-critical (backup-restore with full validation). Moderate for staging. Faster strategies acceptable for dev. |
| **Decides** | Stakeholders |
| **Answer** | We start on the platform team sandbox then test environments where dev and staging are and finally in prod, we can take risks in sandbox, test and prod are where we need to be sure that things work |
| **Project owner** | |
| **22-03-2026** | |

---

## Recommended Action

| Step | Action | Owner | Timeline |
|------|--------|-------|----------|
| 1 | Circulate this brief to stakeholders | You | This week |
| 2 | Schedule decision meeting (30 min) | You | This week |
| 3 | Answer S2, S3 (timeline, resources) | Management | In meeting |
| 4 | Answer S4, S5 (strategy, rollback) | Ops + stakeholders | In meeting |
| 5 | Answer A1 (downtime tiers) | App owners | Within 1 week |
| 6 | Confirm R2 (risk tolerance) | Stakeholders | Within 1 week |

---

## Decision Log

| Date | ID | Decision | Rationale | Changed By |
|------|----|----------|-----------|------------|
| 2026-03-22 | S1 | Discovery first, time-boxed | Validate assumptions before coding; don't get stuck forever | Project lead |
| 2026-03-22 | S2 | 7 work days for tool stack | Focus on tool delivery, not full migration timeline | Management |
| 2026-03-22 | S3 | Kind local → test OpenShift | Test locally first to iterate fast; validate on real cluster before prod | Management |
| 2026-03-22 | S4 | Hybrid (copy/backup) + Velero recovery | Migration can be copy or backup-restore; recovery always via Velero | Ops + stakeholders |
| 2026-03-22 | S5 | Velero backup first, manual restore on failure | Mandatory backup before migration; manual Velero restore if migration fails | Ops + app owners |
| 2026-03-22 | A1 | Tool must be smooth/fast; team handles per-app downtime | Migration team handles app-specific downtime; tool focus on speed/reliability | App owners |
| 2026-03-22 | R2 | Sandbox (risk OK) → test → prod | Iterate fast in sandbox; must work in test; be sure in prod | Stakeholders |

---

**Document Status**: All decisions complete  
**Date**: 2026-03-22  
**Next Step**: Begin discovery phase (7-day tool stack delivery)
