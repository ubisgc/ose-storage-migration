# Todo List: PVC Migration Tool Stack (7-Day Delivery)

## Overview
**Goal**: Deliver a working PVC migration tool stack in 7 work days
**Start**: 2026-03-22
**End**: 2026-03-29 (7 work days)
**Environment Progression**: Local Kind → Test OpenShift → Production (future)

---

## Day 1–2: Discovery and Setup

### Discovery Tasks
- [ ] Run discovery commands from `discovery-plan.md` against sandbox/test cluster
- [ ] Document HNAS StorageClass parameters (E1)
- [ ] Document existing StorageClasses and CSI drivers (E2)
- [ ] Inventory namespaces and PVCs (E3)
- [ ] Confirm Velero installation and status (B1)
- [ ] Check RBAC permissions for Ansible service account (T3)
- [ ] Check SCC constraints (T4)

### Kind Setup Tasks
- [ ] Install `kind` CLI
- [ ] Create Kind cluster with test configuration
- [ ] Install Velero on Kind cluster (MinIO backend)
- [ ] Create test namespace with PVC and pod
- [ ] Verify Velero backup/restore works on Kind

### Deliverables
- [ ] `discovery-findings.md` with all facts gathered
- [ ] Working Kind cluster with Velero

---

## Day 3–4: Local Kind Testing

### Migration Strategy Testing
- [ ] Test **Backup-Restore** strategy on Kind
  - [ ] Velero backup of test namespace
  - [ ] Scale down workload
  - [ ] Delete old PVC
  - [ ] Create new PVC (simulating HNAS)
  - [ ] Velero restore
  - [ ] Verify data integrity
- [ ] Test **Direct Copy** strategy on Kind
  - [ ] Create source and target PVCs
  - [ ] Mount both in migration pod
  - [ ] rsync/rclone data transfer
  - [ ] Verify data integrity
- [ ] Test **Failure/Recovery** scenarios
  - [ ] Simulate migration failure mid-transfer
  - [ ] Velero restore to recover
  - [ ] Verify application restarts

### Ansible Skeleton
- [ ] Create Ansible role structure: `roles/pvc-migration/`
- [ ] Create discovery tasks (gather PVC/namespace info)
- [ ] Create Velero backup task
- [ ] Create migration task (copy or backup-restore)
- [ ] Create validation task
- [ ] Create rollback task (Velero restore)

### Deliverables
- [ ] Tested migration procedures documented
- [ ] Ansible role skeleton with core tasks

---

## Day 5–6: Test OpenShift Validation

### Test Cluster Deployment
- [ ] Deploy Ansible role to test OpenShift cluster
- [ ] Run discovery against test cluster
- [ ] Select test namespace for pilot migration
- [ ] Execute end-to-end migration on test namespace
- [ ] Validate data integrity post-migration
- [ ] Test failure scenario and Velero restore

### Refinement
- [ ] Fix any issues found during testing
- [ ] Refine Ansible tasks based on real-world execution
- [ ] Update documentation with lessons learned

### Deliverables
- [ ] Working Ansible role validated on OpenShift
- [ ] Test migration report
- [ ] Updated documentation

---

## Day 7: Finalization

### Documentation
- [ ] Update `design-review.md` with final design
- [ ] Create `migration-runbook.md` for operators
- [ ] Document known limitations and workarounds
- [ ] Update `open-questions.md` with answered questions

### Handover
- [ ] Final code review of Ansible role
- [ ] Demo to stakeholders
- [ ] Production readiness assessment
- [ ] Identify remaining blockers for production

### Deliverables
- [ ] Complete tool stack (Ansible role + documentation)
- [ ] Handover document
- [ ] Production readiness checklist

---

## Status

| Day | Phase | Status | Notes |
|-----|-------|--------|-------|
| 1 | Discovery | ☐ Not started | |
| 2 | Discovery | ☐ Not started | |
| 3 | Local Testing | ☐ Not started | |
| 4 | Local Testing | ☐ Not started | |
| 5 | Test OpenShift | ☐ Not started | |
| 6 | Test OpenShift | ☐ Not started | |
| 7 | Finalization | ☐ Not started | |

---

## Blockers and Dependencies

| Blocker | Owner | Status | Notes |
|---------|-------|--------|-------|
| Cluster access (sandbox/test) | Platform team | ☐ Pending | Needed for discovery |
| HNAS StorageClass availability | Storage team | ☐ Pending | Needed for real testing |
| Velero installation | Operations | ☐ Pending | Confirmed required |

---

## Key Decisions Applied

| Decision | Impact on Implementation |
|----------|-------------------------|
| S1: Discovery first | Days 1-2 dedicated to discovery before coding |
| S2: 7-day timeline | Strict time-boxing; defer nice-to-haves |
| S3: Kind local testing | Days 3-4 on Kind before touching real cluster |
| S4: Hybrid with Velero recovery | Tool supports copy + backup-restore; Velero always for recovery |
| S5: Velero backup first | Every migration starts with `velero backup create` |
| R2: Sandbox → test → prod | Day 1-2 sandbox risk OK; Day 5-6 test env must work; prod later |

---

**Document Status**: Active  
**Date**: 2026-03-22  
**Owner**: Development team
