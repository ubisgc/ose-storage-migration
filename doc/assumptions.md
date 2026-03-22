# Assumptions: PVC Storage Migration to HNAS

## Purpose
This document catalogs all assumptions underlying the migration design. Each assumption must be validated during the discovery phase before production implementation.

---

## Environment Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A1** | HNAS StorageClass will be available and functional in the cluster before migration begins. | `oc get storageclass <hnas-sc>` and test PVC creation. | **High** – blocks all migration. | P0 |
| **A2** | The cluster runs a supported Kubernetes/OpenShift version with PVC/PV abstractions. | `oc version` or `kubectl version`. | **High** – fundamental platform mismatch. | P0 |
| **A3** | CSI drivers for both source and target storage are installed and healthy. | `oc get csidrivers`; check driver pods. | **High** – PVC binding failures. | P0 |
| **A4** | HNAS has sufficient capacity for all migrated PVCs. | Query HNAS capacity; compare to total PVC sizes. | **High** – migration cannot complete. | P0 |
| **A5** | Network connectivity exists between the remote Ansible workstation and the cluster API. | Ansible ping or `oc whoami` from workstation. | **Medium** – automation blocked. | P1 |
| **A6** | Network bandwidth between storage systems is sufficient for data transfer within maintenance windows. | Estimate transfer time from data volume and bandwidth. | **Medium** – extended downtime. | P1 |

---

## Workload Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A7** | Applications tolerate planned maintenance windows (graceful shutdown/startup). | Interview application teams; review SLAs. | **High** – forces complex zero-downtime approach. | P0 |
| **A8** | Application teams can provide quiescing procedures for stateful workloads. | Request procedures from app teams; test in non-prod. | **High** – data inconsistency if writes during copy. | P0 |
| **A9** | No cross-namespace PVC sharing exists (PVCs are namespace-scoped). | Audit PVC references across namespaces. | **Medium** – requires special handling. | P1 |
| **A10** | Workloads are a mix of Deployments (stateless) and StatefulSets (stateful). | `oc get deployments,statefulsets -A`. | **Low** – affects strategy selection only. | P2 |
| **A11** | Applications do not depend on storage-specific features (e.g., file locking semantics). | Interview app teams; test migration. | **Medium** – application failures post-migration. | P1 |

---

## Backup and Recovery Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A12** | Backup infrastructure (Velero/restic or equivalent) exists and is reliable. | Check for Velero deployment; test backup/restore. | **High** – backup-restore strategy unavailable. | P0 |
| **A13** | Recent backups exist for all namespaces targeted for migration. | Query backup system for last backup time per namespace. | **High** – no rollback safety net. | P0 |
| **A14** | Backups are verified restorable (not just created). | Perform test restore to temporary namespace. | **High** – backup may be corrupt. | P1 |

---

## Tool and Automation Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A15** | rsync/rclone can preserve POSIX permissions, ownership, and SELinux context. | Test copy between PVCs; compare metadata. | **Medium** – application startup failures. | P1 |
| **A16** | rsync/rclone (or equivalent copy tools) are available in the cluster or in a container image. | Check available images; test deployment. | **Medium** – copy strategy blocked. | P1 |
| **A17** | Ansible remote workstation has required tools (kubectl/oc, ansible, python k8s module). | Verify workstation setup. | **Medium** – automation blocked. | P1 |
| **A18** | Ansible service account has required RBAC permissions (create/modify PVCs, pods, deployments). | Test API calls from Ansible. | **High** – automation fails. | P0 |

---

## Storage Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A19** | Source and/or target storage supports snapshots (for snapshot-based strategy). | Check CSI driver capabilities; test snapshot creation. | **Low** – snapshot strategy unavailable; fallback to others. | P2 |
| **A20** | Both source and target PVCs can be mounted simultaneously in the same pod (for direct copy). | Create test pod mounting two PVCs from different StorageClasses. | **Medium** – direct copy strategy blocked. | P1 |
| **A21** | HNAS StorageClass supports the access modes required by existing PVCs (RWO, RWX). | Compare existing PVC access modes to HNAS capabilities. | **High** – cannot bind new PVCs. | P0 |
| **A22** | Storage-level replication between source and HNAS is not available (assumption of absence). | Confirm with storage team. | **Low** – if available, enables faster strategy. | P2 |

---

## Security and Access Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A23** | Security Context Constraints (SCCs) allow pods with required privileges for migration (if needed). | Test pod creation with required security context. | **Medium** – migration pods blocked. | P1 |
| **A24** | Network policies do not block migration pod communication. | Review network policies; test connectivity. | **Low** – can adjust if needed. | P2 |
| **A25** | Resource quotas allow temporary resource consumption during migration (especially blue-green). | Check quota usage; estimate migration resource needs. | **Medium** – migration blocked by quotas. | P1 |

---

## Operational Assumptions

| ID | Assumption | Validation Method | Risk if Wrong | Priority |
|----|------------|-------------------|---------------|----------|
| **A26** | Maintenance windows can be scheduled for each namespace migration. | Coordinate with application owners and operations. | **High** – cannot execute migration. | P0 |
| **A27** | Change management process exists and will be followed. | Review existing change process; align migration workflow. | **Medium** – compliance issues. | P1 |
| **A28** | Monitoring and alerting can be enhanced to track migration progress. | Review existing monitoring; define migration dashboards. | **Low** – reduced visibility. | P2 |
| **A29** | Human operators are available to monitor and intervene during migration execution. | Confirm staffing for maintenance windows. | **Medium** – delayed response to issues. | P1 |
| **A30** | Post-migration stability period (e.g., 24–48 hours) is acceptable before cleanup. | Coordinate with operations and app teams. | **Low** – affects cleanup timing only. | P2 |

---

## Validation Priority Summary

### P0 – Must Validate Before Any Migration
A1, A4, A7, A8, A12, A13, A18, A21, A26

### P1 – Must Validate Before Production Migration
A5, A6, A9, A11, A14, A15, A16, A17, A20, A23, A25, A27, A29

### P2 – Validate During Discovery (Lower Priority)
A2, A3, A10, A19, A22, A24, A28, A30

---

## Discovery Phase Validation Plan

1. **Week 1**: Validate all P0 assumptions (cluster, storage, backup, RBAC)
2. **Week 2**: Validate all P1 assumptions (tools, connectivity, policies)
3. **Ongoing**: Validate P2 assumptions as part of PoC and pilot phases

**Document Status**: Review-Ready  
**Date**: 2026-03-22  
**Owner**: Platform team + Application teams
