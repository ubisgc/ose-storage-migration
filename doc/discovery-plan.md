# Discovery Plan: Cluster and Storage Inventory

## Purpose
This document lists the commands and procedures to gather facts that answer the open discovery questions (E1–E5, A4, A5, B1, T3, T4). Execute these when cluster access is available.

## Timeline
**7 work days to deliver tool stack** (per stakeholder decision S2)

| Day | Activity | Environment |
|-----|----------|-------------|
| 1–2 | Discovery + Kind setup | Local + sandbox cluster |
| 3–4 | Local Kind testing | Local Kind cluster |
| 5–6 | Test OpenShift validation | Test OpenShift cluster |
| 7 | Finalization | Documentation |

---

## Prerequisites

| Requirement | Check |
|-------------|-------|
| `oc` or `kubectl` installed | `oc version --client` |
| Cluster credentials configured | `oc whoami` |
| Sufficient RBAC to read resources | `oc auth can-i get pods -A` |
| `kind` installed (for local testing) | `kind version` |
| `docker` or `podman` installed | `docker version` |
| Velero CLI installed | `velero version --client-only` |

---

## Discovery Commands by Question

### E1: HNAS StorageClass Parameters

**Question**: What are the HNAS StorageClass parameters (block vs file, access modes, reclaim policy)?

```bash
# List all StorageClasses
oc get storageclass -o wide

# Get detailed HNAS StorageClass config
oc get storageclass <hnas-sc-name> -o yaml

# Check provisioner type
oc get storageclass <hnas-sc-name> -o jsonpath='{.provisioner}'

# Check volume binding mode
oc get storageclass <hnas-sc-name> -o jsonpath='{.volumeBindingMode}'

# Check reclaim policy
oc get storageclass <hnas-sc-name> -o jsonpath='{.reclaimPolicy}'
```

**What this tells us**:
- Is HNAS block (CSI) or file (NFS)?
- Supported access modes (RWO, RWX)
- Immediate vs WaitForFirstConsumer binding
- Retain vs Delete reclaim policy
- Copy tool selection (rsync for file, block-level for block)

---

### E2: Existing StorageClasses and CSI Drivers

**Question**: What existing StorageClasses and CSI drivers are configured?

```bash
# List all StorageClasses with details
oc get storageclass -o wide

# List all CSI drivers
oc get csidrivers

# Get CSI driver capabilities
oc get csidrivers -o yaml

# Check which CSI drivers support snapshots
oc get csidrivers -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.volumeLifecycleModes}{"\n"}{end}'
```

**What this tells us**:
- Source storage backends in use
- Which CSI drivers are available
- Snapshot/clone support per driver
- Migration strategy options per source StorageClass

---

### E3: Namespace and PVC Inventory

**Question**: How many namespaces require migration, and what is the total PVC data volume?

```bash
# Count namespaces with PVCs
oc get pvc -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort -u | wc -l

# List all PVCs with size and StorageClass
oc get pvc -A -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
SIZE:.spec.resources.requests.storage,\
STORAGECLASS:.spec.storageClassName,\
STATUS:.status.phase,\
ACCESSMODES:.spec.accessModes

# Total requested storage
oc get pvc -A -o jsonpath='{range .items[*]}{.spec.resources.requests.storage}{"\n"}{end}' | paste -sd+ | bc

# PVC count per namespace
oc get pvc -A -o json | jq -r '.items[].metadata.namespace' | sort | uniq -c | sort -rn

# PVCs NOT using HNAS (migration candidates)
oc get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName != "<hnas-sc-name>") | "\(.metadata.namespace)/\(.metadata.name) \(.spec.resources.requests.storage) \(.spec.storageClassName)"'
```

**What this tells us**:
- Total migration scope (namespaces, PVCs, data volume)
- Which PVCs need migration (not already on HNAS)
- Capacity planning for HNAS
- Timeline estimation

---

### E4: Snapshot Capability

**Question**: Does the cluster have VolumeSnapshot CRDs, and do source/target CSI drivers support snapshots?

```bash
# Check if VolumeSnapshot CRDs exist
oc get crd | grep -i snapshot

# List VolumeSnapshotClasses if they exist
oc get volumesnapshotclass 2>/dev/null || echo "VolumeSnapshotClass not available"

# Check CSI driver snapshot capability
oc get csidrivers -o json | jq '.items[] | {name: .metadata.name, lifecycleModes: .spec.volumeLifecycleModes}'
```

**What this tells us**:
- Whether snapshot-based migration is possible
- Which storage backends support snapshots
- Fallback to backup-restore or direct copy if no snapshots

---

### E5: Cluster Version

**Question**: What Kubernetes/OpenShift version is running?

```bash
# Server version
oc version

# Node OS and kernel versions
oc get nodes -o wide

# OpenShift-specific version (if applicable)
oc get clusterversion 2>/dev/null || echo "Not an OpenShift cluster"
```

**What this tells us**:
- Feature availability (CSI snapshots, etc.)
- Compatibility with migration tools
- Upgrade schedule constraints

---

### A4: Cross-Namespace PVC Sharing

**Question**: Are any PVCs shared across namespaces?

```bash
# Get all pods with PVC mounts across all namespaces
oc get pods -A -o json | jq -r '
  .items[] | 
  select(.spec.volumes != null) |
  .spec.volumes[] | 
  select(.persistentVolumeClaim != null) |
  "\(.persistentVolumeClaim.claimName)"
' | sort -u

# Check if any PV is claimed by PVCs in multiple namespaces
oc get pv -o json | jq -r '
  .items[] |
  select(.spec.claimRef != null) |
  {
    pv: .metadata.name,
    pvc: .spec.claimRef.name,
    namespace: .spec.claimRef.namespace,
    accessModes: .spec.accessModes
  }
'

# For RWX PVCs, check if mounted in multiple namespaces
oc get pvc -A -o json | jq -r '
  .items[] | 
  select(.spec.accessModes[] == "ReadWriteMany") |
  "\(.metadata.namespace)/\(.metadata.name) \(.spec.accessModes)"
'
```

**What this tells us**:
- Whether namespace-by-namespace isolation is possible
- Special handling needed for shared PVCs
- RWX PVCs that may span namespaces

---

### A5: Workload Types per Namespace

**Question**: What workload types exist per namespace?

```bash
# StatefulSets per namespace
oc get statefulset -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas,PVCs:.spec.volumeClaimTemplates[*].metadata.name

# Deployments per namespace
oc get deployment -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas

# DaemonSets per namespace
oc get daemonset -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name

# Jobs/CronJobs per namespace
oc get jobs,cronjobs -A

# Summary: workload types per namespace
echo "=== StatefulSets per namespace ==="
oc get statefulset -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort | uniq -c | sort -rn

echo "=== Deployments per namespace ==="
oc get deployment -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort | uniq -c | sort -rn
```

**What this tells us**:
- Which namespaces have stateful workloads (StatefulSets)
- Which namespaces are stateless (Deployments only)
- Strategy selection per namespace
- Quiescing complexity

---

### B1: Backup Infrastructure

**Question**: Does Velero or equivalent backup infrastructure exist?

```bash
# Check for Velero namespace
oc get namespace velero 2>/dev/null || echo "Velero namespace not found"

# Check Velero pods
oc get pods -n velero 2>/dev/null || echo "Velero not deployed"

# Check for Velero backups
oc get backups -n velero 2>/dev/null || echo "Cannot list backups"

# Check for other backup solutions (restic, k8up, etc.)
oc get pods -A | grep -iE 'velero|restic|k8up|backup'

# Check for VolumeSnapshot backups
oc get volumesnapshot -A 2>/dev/null || echo "No VolumeSnapshots found"
```

**What this tells us**:
- Whether backup-restore strategy is feasible
- Existing backup coverage
- Backup tool available for migration

---

### T3: Ansible RBAC Permissions

**Question**: Does the Ansible service account have required RBAC permissions?

```bash
# Set to your Ansible service account
ANSIBLE_SA="<ansible-service-account>"
ANSIBLE_NS="<ansible-namespace>"

# Test key permissions
echo "=== PVC permissions ==="
oc auth can-i get pvc -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i create pvc -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i delete pvc -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}

echo "=== Pod permissions ==="
oc auth can-i get pods -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i create pods -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i delete pods -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}

echo "=== Deployment/StatefulSet permissions ==="
oc auth can-i get deployments -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i patch deployments -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i get statefulsets -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
oc auth can-i scale statefulsets -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}

echo "=== Exec permissions (for migration pods) ==="
oc auth can-i create pods/exec -A --as=system:serviceaccount:${ANSIBLE_NS}:${ANSIBLE_SA}
```

**What this tells us**:
- Whether Ansible can execute migration operations
- RBAC gaps that need to be addressed
- Security constraints

---

### T4: Security Context Constraints

**Question**: What SCCs are required and permitted for migration pods?

```bash
# List all SCCs
oc get scc

# Check if anyuid is available
oc get scc anyuid -o yaml

# Check restricted SCC (default)
oc get scc restricted -o yaml

# Test: can we create a privileged pod? (for dual-mount migration)
oc auth can-i create pods --as=system:serviceaccount:<ns>:default -n <test-ns>
```

**What this tells us**:
- Whether migration pods can run with required privileges
- SCC constraints that may block dual-mount strategies
- Need for custom SCC or service account configuration

---

## Execution Checklist

### When cluster access is available:

```
[ ] Verify cluster access: oc whoami
[ ] Run E1 commands: HNAS StorageClass parameters
[ ] Run E2 commands: Existing StorageClasses and CSI drivers
[ ] Run E3 commands: Namespace and PVC inventory
[ ] Run E4 commands: Snapshot capability
[ ] Run E5 commands: Cluster version
[ ] Run A4 commands: Cross-namespace PVC sharing
[ ] Run A5 commands: Workload types per namespace
[ ] Run B1 commands: Backup infrastructure
[ ] Run T3 commands: Ansible RBAC permissions
[ ] Run T4 commands: Security Context Constraints
[ ] Document findings in discovery report
[ ] Update design based on findings
```

---

## Output Format

After running all commands, compile findings into:

```markdown
## Discovery Findings

### E1: HNAS StorageClass
- [Finding]

### E2: Existing Storage
- [Finding]

### E3: Migration Scope
- [Finding]
...
```

---

**Document Status**: Ready for execution  
**Date**: 2026-03-22  
**Next Step**: Execute when cluster access is available

---

## Appendix: Kind Local Testing Setup

### Create Kind Cluster with Velero

```bash
# Create Kind cluster config
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /tmp/kind-data
    containerPath: /data
EOF

# Create cluster
kind create cluster --name pvc-migration-test --config kind-config.yaml

# Verify cluster
kubectl cluster-info --context kind-pvc-migration-test
```

### Install Velero on Kind

```bash
# Install MinIO as backup storage (for local testing)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: velero
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: velero
spec:
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        env:
        - name: MINIO_ACCESS_KEY
          value: minio
        - name: MINIO_SECRET_KEY
          value: minio123
        ports:
        - containerPort: 9000
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: velero
spec:
  selector:
    app: minio
  ports:
  - port: 9000
EOF

# Install Velero CLI
# (Download from https://github.com/vmware-tanzu/velero/releases)

# Install Velero with MinIO backend
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.6.0 \
  --bucket velero \
  --secret-file ./velero-credentials.txt \
  --use-volume-snapshots=false \
  --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio.velero.svc:9000

# Create credentials file first
cat > velero-credentials.txt <<EOF
[default]
aws_access_key_id=minio
aws_secret_access_key=minio123
EOF
```

### Test Workload for Migration

```bash
# Create test namespace
kubectl create namespace migration-test

# Create test PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: migration-test
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Create test pod with PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: migration-test
spec:
  containers:
  - name: test
    image: busybox
    command: ["sh", "-c", "echo 'test data' > /data/test.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc
EOF

# Verify data written
kubectl exec -n migration-test test-pod -- cat /data/test.txt
```

### Test Velero Backup/Restore

```bash
# Take backup
velero backup create test-backup --include-namespaces migration-test

# Check backup status
velero backup describe test-backup --details

# Simulate failure: delete PVC
kubectl delete pod test-pod -n migration-test
kubectl delete pvc test-pvc -n migration-test

# Restore
velero restore create test-restore --from-backup test-backup

# Verify data restored
kubectl exec -n migration-test test-pod -- cat /data/test.txt
```
