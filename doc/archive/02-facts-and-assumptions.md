# Facts and Assumptions: PVC Storage Migration

## Facts (Known Information)

### Platform Constraints
1. **Kubernetes/OpenShift**: The target platform supports PVC/PV abstractions
2. **StorageClass Model**: Storage is abstracted through StorageClass objects
3. **PVC Lifecycle**: PVCs are bound to PVs, which map to actual storage
4. **Namespace Isolation**: Resources are scoped by namespace in Kubernetes
5. **Ansible Automation**: Ansible can interact with Kubernetes API via k8s modules

### Storage Migration Fundamentals
1. **No Native Migration**: Kubernetes does not provide built-in PVC migration
2. **Data Copy Required**: Migration necessitates data movement between storage backends
3. **Workload Impact**: Data migration typically requires workload interruption
4. **Ordering Matters**: StatefulSets require careful ordering (scale down, migrate, scale up)
5. **Access Modes**: RWO vs RWX affects migration strategy

### HNAS Storage Context
1. **Provided StorageClass**: HNAS StorageClass will be available in cluster
2. **Block or File**: HNAS could provide either block (iSCSI/FC) or file (NFS) storage
3. **Performance Tier**: HNAS may have different performance characteristics than existing storage
4. **Capacity**: HNAS has finite capacity that must be considered

## Assumptions (Require Validation)

### Environment Assumptions
1. **Cluster Access**: Remote workstation has kubectl/oc access to target cluster
2. **Ansible Connectivity**: Ansible can reach both cluster API and storage management interfaces
3. **Namespace Boundaries**: Applications are reasonably isolated by namespace
4. **PVC Naming**: PVCs follow predictable naming conventions
5. **No Cross-Namespace PVC Sharing**: PVCs are not shared across namespaces

### Workload Assumptions
1. **Downtime Tolerance**: Applications can tolerate planned maintenance windows
2. **Stateful vs Stateless**: Mix of StatefulSets and Deployments exists
3. **Data Criticality**: All data must be preserved (no disposable data)
4. **Backup Availability**: Existing backup solutions can be leveraged
5. **Application Quiescing**: Applications can be gracefully stopped

### Technical Assumptions
1. **Copy Tools Available**: Tools like rsync, rclone, or storage-level replication exist
2. **Snapshot Support**: Source or target storage supports snapshots
3. **Network Bandwidth**: Sufficient bandwidth for data transfer exists
4. **Storage Permissions**: Ansible/service accounts have necessary storage permissions
5. **Rollback Capability**: Can revert to original storage if migration fails

### Process Assumptions
1. **Maintenance Windows**: Scheduled downtime windows are acceptable
2. **Operator Availability**: Human operators can monitor and intervene if needed
3. **Testing Environment**: Test cluster or namespace available for validation
4. **Documentation**: Existing runbooks or procedures may exist
5. **Change Management**: Formal change process exists for production changes

## Unknowns Requiring Discovery

### Cluster Environment
1. What Kubernetes/OpenShift version is running?
2. What existing StorageClasses are configured?
3. What CSI drivers are in use?
4. What is the cluster's upgrade/patch schedule?

### Storage Details
1. What are the HNAS StorageClass parameters?
2. What are the existing storage backends?
3. What is the total data volume to migrate?
4. What are the performance requirements?

### Workload Inventory
1. How many namespaces require migration?
2. What workload types exist per namespace?
3. What are the data sensitivity classifications?
4. What are the application-specific shutdown/startup procedures?

### Operational Constraints
1. What is the acceptable maintenance window duration?
2. What monitoring/alerting is in place?
3. What is the rollback time objective?
4. What is the success criteria per namespace?

## Risk Factors Based on Assumptions

### High Risk Assumptions (if wrong)
1. **Downtime Tolerance**: If applications cannot tolerate downtime
2. **Backup Availability**: If backups don't exist or are unreliable
3. **Rollback Capability**: If rollback is not possible after migration starts
4. **Namespace Isolation**: If PVCs are shared across namespaces

### Medium Risk Assumptions
1. **Copy Tool Availability**: If required tools aren't available
2. **Network Bandwidth**: If transfer takes longer than maintenance window
3. **Application Quiescing**: If applications don't stop gracefully

### Low Risk Assumptions
1. **Ansible Connectivity**: Likely already established for remote management
2. **Cluster Access**: Required for any automation approach
3. **PVC Naming**: Can be discovered during inventory phase

## Next Steps
1. Validate critical assumptions with platform team
2. Gather cluster and storage inventory
3. Identify test namespace for proof-of-concept
4. Document application-specific migration requirements

## Maturity: Brainstorming
This document captures current knowledge and assumptions. Assumptions should be validated during discovery phase.