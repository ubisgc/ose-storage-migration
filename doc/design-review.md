# Design Review: PVC Storage Migration to HNAS

## 0. Decisions Made

| ID | Decision | Date |
|----|----------|------|
| S1 | Discovery phase first, but time-boxed | 2026-03-22 |
| S2 | 7 work days to deliver tool stack (not full migration) | 2026-03-22 |
| S3 | Local Kind cluster for testing first, then test OpenShift | 2026-03-22 |
| S4 | Hybrid approach — copy or backup/restore for migration, Velero for recovery | 2026-03-22 |
| S5 | Velero backup as first migration step, manual restore on failure | 2026-03-22 |
| A1 | Tool must be smooth/fast; downtime handled per-app by migration team | 2026-03-22 |
| R2 | Progression: sandbox (risk OK) → test (dev/staging) → prod (must work) | 2026-03-22 |

---

## 1. Problem Framing

Design a tool stack for namespace-by-namespace migration of PVC-backed workloads in Kubernetes/OpenShift to a new HNAS-backed StorageClass. Automation is initiated from a remote workstation via Ansible.

**Scope**: Deliver a working tool stack in **7 work days**. The tool must support:
- Velero backup as first step (mandatory before any migration)
- Migration via copy or backup/restore strategy
- Manual Velero restore on migration failure
- Testing on local Kind cluster, then test OpenShift cluster

**Core Requirements:**
- Zero data loss
- Minimal planned downtime (maintenance windows acceptable)
- Velero backup before every migration (rollback via manual restore)
- Namespace isolation maintained during migration
- Automated, auditable, repeatable process

---

## 2. Facts

| # | Fact |
|---|------|
| 1 | Kubernetes/OpenShift has no native PVC migration capability; external data movement is required. |
| 2 | PVCs are bound 1:1 to PVs, which map to underlying storage; migration requires new PVs on HNAS. |
| 3 | Namespace boundaries provide natural scoping for migration sequencing. |
| 4 | Ansible can interact with the Kubernetes API via `kubernetes.core.k8s` modules from a remote workstation. |
| 5 | StatefulSets impose ordered pod management; scaling down is required before PVC replacement. |
| 6 | RWO (ReadWriteOnce) PVCs can only be mounted by one pod at a time; dual-mount copy strategies depend on access mode. |
| 7 | OpenShift enforces Security Context Constraints (SCCs) that may restrict privileged migration pods. |
| 8 | CSI driver capabilities (snapshot, clone) vary by storage backend and are not guaranteed across vendors. |
| 9 | **Velero is the required backup tool** — backup before migration, manual restore on failure. |
| 10 | **7 work days** to deliver the tool stack. |

---

## 3. Assumptions

| # | Assumption | Risk if Wrong |
|---|------------|---------------|
| A1 | HNAS StorageClass will be available and functional in the cluster before migration begins. | **High** – blocks all migration. |
| A2 | Applications tolerate planned maintenance windows (graceful shutdown/startup). | **High** – forces live-migration or zero-downtime approaches. |
| A3 | No cross-namespace PVC sharing exists (PVCs are namespace-scoped). | **Medium** – requires special handling if violated. |
| A4 | **Velero is installed and operational** in the target cluster. | **Critical** – confirmed requirement; blocks migration if missing. |
| A5 | rsync/rclone can preserve POSIX permissions, ownership, and SELinux context. | **Medium** – application startup failures. |
| A6 | Network bandwidth between storage systems is sufficient for data transfer within maintenance windows. | **Medium** – extended downtime. |
| A7 | Ansible remote workstation has stable connectivity to the cluster API. | **Medium** – migration stuck mid-execution. |
| A8 | Source and/or target storage supports snapshots (for snapshot-based strategy). | **Low** – snapshot strategy unavailable, fallback to others. |
| A9 | Application teams can provide quiescing procedures for stateful workloads. | **High** – data inconsistency if writes occur during copy. |
| A10 | HNAS has sufficient capacity for all migrated PVCs. | **High** – migration cannot complete. |

---

## 4. Constraints

| Constraint | Implication |
|------------|-------------|
| **Platform**: Kubernetes/OpenShift | Must use PVC/PV abstractions, respect RBAC, SCC, quotas. |
| **Target Storage**: Provided HNAS StorageClass | Cannot modify HNAS configuration; must work within its capabilities. |
| **Sequencing**: Namespace by namespace | Limits parallelism; reduces blast radius. |
| **Automation**: Ansible from remote workstation | Network dependency; must handle connectivity loss gracefully. |
| **Timeline**: 7 work days for tool stack | Scope is tool delivery, not full migration execution. |
| **Backup**: Velero mandatory | Every migration starts with Velero backup; restore on failure. |
| **Testing**: Kind local → test OpenShift | Must work in local Kind cluster first, then real test cluster. |
| **Safety**: No data loss | Mandatory Velero backups, validation, manual restore on failure. |

---

## 5. Options Considered

| Option | Description | Best For | Key Risk |
|--------|-------------|----------|----------|
| **1. Backup-Restore (Velero)** | Velero backup → scale down → delete old PVC → create new PVC on HNAS → Velero restore → scale up | Large data; primary recovery method | Extended downtime; Velero reliability |
| **2. Direct Copy** | Scale down → mount both PVCs → rsync/rclone → update workload → scale up | Small data (<10GB), dual-mount support | Dual-mount may be impossible; no intermediate backup |
| **3. Storage-Level Replication** | Configure array-level replication → sync → cutover | Cross-vendor replication support | Unlikely between different storage vendors |
| **4. Snapshot-Based** | Snapshot source → create PVC from snapshot on HNAS → incremental sync → cutover | CSI snapshot support on both backends | Snapshot portability between vendors |
| **5. Blue-Green Deployment** | Deploy duplicate workload on HNAS → copy data → switch traffic → decommission old | Stateless applications | Double resource consumption; session state |
| **6. Hybrid** | Select strategy per workload type based on characteristics | Mixed environments | Operational complexity; multiple procedures |
| **7. Phased (App Replication)** | Use application-level replication (e.g., DB replication) to sync → cutover | Databases with built-in replication | Application-specific; not generic |

---

## 6. Trade-offs

| Factor | Backup-Restore | Direct Copy | Snapshot | Blue-Green | Hybrid |
|--------|----------------|-------------|----------|------------|--------|
| **Downtime** | High | Medium | Low | Very Low | Variable |
| **Complexity** | Low | Medium | High | High | High |
| **Rollback** | Excellent (Velero) | Poor | Good | Excellent | Good (Velero) |
| **Automation** | Good | Good | Medium | Good | Medium |
| **Safety** | High | Medium | Medium | High | High |
| **Tooling Dependency** | Velero | rsync/rclone | CSI snapshots | Networking | All |

**Key Trade-off**: Simpler strategies (backup-restore) have higher downtime; faster strategies (blue-green, snapshot) have higher complexity or narrower applicability. **Velero is always used for recovery regardless of migration strategy.**

---

## 7. Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Data loss during transfer** | Critical | Velero backup before migration; checksum validation; manual restore on failure |
| **Extended downtime** | High | Strategy selection based on data volume; performance testing; maintenance windows |
| **Rollback failure** | High | Velero backup/restore tested; retain original PVCs until validation complete |
| **Dual-mount incompatibility** | Medium | Test during discovery; fallback to backup-restore |
| **Ansible connectivity loss** | Medium | Idempotent operations; checkpointing; manual recovery procedures |
| **Permission/ownership mismatch** | Medium | Metadata preservation testing; post-migration validation |
| **Application quiescing failure** | High | Documented app-specific procedures; application team engagement |
| **HNAS capacity exhaustion** | High | Capacity planning during discovery; quota enforcement |
| **7-day timeline pressure** | Medium | Focus on core functionality; defer nice-to-haves |

---

## 8. Recommended Design Direction

**Hybrid Approach with Velero Recovery and Local-First Testing**

### Migration Strategies
| Strategy | When to Use | Migration Method | Recovery Method |
|----------|-------------|------------------|-----------------|
| **Copy** | Small data, dual-mount possible | rsync/rclone between PVCs | Velero restore |
| **Backup-Restore** | Large data, default | Velero backup/restore | Velero restore |
| **Blue-Green** | Stateless apps | Deploy new + copy data | Velero restore |

### Recovery (Always Velero)
1. Velero backup taken before any migration starts
2. If migration fails at any point: manual Velero restore
3. Original PVCs retained until validation complete

### Implementation Phases (7 Work Days)
| Day | Phase | Activities |
|-----|-------|------------|
| 1–2 | Discovery | Gather cluster inventory, validate Velero, test HNAS StorageClass |
| 3–4 | Local Testing (Kind) | Set up local Kind cluster with Velero; test copy and backup-restore strategies |
| 5–6 | Test OpenShift | Deploy to test OpenShift cluster; validate with real PVCs |
| 7 | Finalization | Documentation, handover, production readiness assessment |

### Validation Framework (Four Gates)
1. **Gate 1 – Pre-Migration**: Go/No-Go checks (namespace, storage, app, Velero backup complete)
2. **Gate 2 – During Migration**: Continuous monitoring (transfer integrity, app state, resource impact)
3. **Gate 3 – Post-Migration**: Success verification (data integrity, app functionality, storage config)
4. **Gate 4 – Handback**: Sign-off (app team acceptance, documentation, cleanup)

### Testing Progression
1. **Sandbox (Day 1–2)**: Risk OK, iterate fast
2. **Test Environment (Day 5–6)**: Dev/staging workloads, validate end-to-end
3. **Production**: Only after test env validation passes

---

## 9. Open Questions (Remaining)

| # | Question | Decision Owner | Impact |
|---|----------|----------------|--------|
| Q1 | What are the HNAS StorageClass parameters (block vs file, access modes, performance)? | Storage team | Strategy feasibility |
| Q2 | What existing StorageClasses and CSI drivers are in use? | Platform team | Tool compatibility |
| Q3 | How many namespaces and total PVC data volume require migration? | Platform team | Timeline and capacity |
| Q5 | Confirm Velero is installed and operational in target cluster | Operations | Critical path |
| Q6 | Can both source and target PVCs be mounted simultaneously? | Platform team (test) | Direct copy feasibility |
| Q7 | What SCC/RBAC constraints exist for privileged migration pods? | Security team | Automation design |

---

## 10. Explicit Non-Goals

| # | Non-Goal |
|---|----------|
| 1 | Cross-namespace data migration in a single operation |
| 2 | Application-level data transformation during migration |
| 3 | Storage array or HNAS configuration (assumes HNAS is pre-provisioned) |
| 4 | Network, firewall, or VPN configuration |
| 5 | RBAC or security policy changes beyond minimum migration requirements |
| 6 | Backup solution replacement (Velero is leveraged, not replaced) |
| 7 | Full production migration execution (scope is tool stack delivery) |
| 8 | Selection of a single migration strategy for all workloads |
| 9 | Zero-downtime migration (planned maintenance windows are acceptable) |
| 10 | Migration of non-PVC-backed workloads |
| 11 | Automated rollback (manual Velero restore on failure is acceptable) |

---

**Document Status**: Updated with stakeholder decisions  
**Date**: 2026-03-22  
**Next Step**: Begin discovery phase (7-day tool stack delivery)
