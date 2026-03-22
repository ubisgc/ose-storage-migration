# Problem Framing: PVC Storage Migration to HNAS

## Mission Statement
Design a safe, reviewable approach for migrating Kubernetes/OpenShift PVC-backed workloads from existing storage to a provided HNAS StorageClass, executed namespace by namespace, with automation initiated from a remote workstation through Ansible.

## Core Requirements
1. **Safety First**: No data loss, minimal downtime, rollback capability
2. **Namespace Isolation**: Migration must be scoped and sequenced by namespace
3. **Automation**: Remote workstation-driven via Ansible
4. **Reviewable Design**: Produce a design package for human approval before implementation
5. **Non-Disruptive**: Minimize impact on running workloads

## Key Constraints
- **Platform**: Kubernetes/OpenShift environments
- **Target Storage**: Provided HNAS StorageClass (specific parameters TBD)
- **Migration Unit**: Namespace-by-namespace
- **Automation Tool**: Ansible initiated from remote workstation
- **Scope**: Design only - no production implementation or execution

## Success Criteria
1. Complete migration of all PVCs in target namespace to HNAS StorageClass
2. Zero data loss
3. Workload continuity maintained (minimal planned downtime acceptable)
4. Rollback capability at each namespace migration
5. Automated, repeatable process
6. Clear operator workflow and validation steps

## Non-Goals (Explicitly Out of Scope)
- Cross-namespace data migration in single operation
- Application-level data transformation
- Storage array configuration (assumes HNAS is already provisioned)
- Network or firewall configuration
- RBAC/Security policy changes beyond migration needs
- Backup solution replacement (though backups may be used in migration)

## Unknowns Requiring Investigation
1. **Current State**:
   - Existing StorageClass types and configurations
   - PVC sizes and access modes in use
   - Workload types (StatefulSets vs Deployments, etc.)
   - Current reclaim policies and volume binding modes
   
2. **Target State**:
   - HNAS StorageClass parameters
   - HNAS capabilities and limitations
   - Performance characteristics
   
3. **Migration Scope**:
   - Total number of namespaces
   - PVC count and total data volume
   - Application sensitivity to downtime
   - Existing backup/snapshot infrastructure

## Initial Questions for Brainstorming
1. What are the viable migration strategies for PVC data?
2. How do we handle StatefulSets vs stateless workloads differently?
3. What pre-migration checks are required per namespace?
4. What is the minimal viable automation vs. full automation?
5. How do we validate success before proceeding to next namespace?

## Maturity: Brainstorming
This document frames the problem space. Next steps: gather facts and assumptions.