## bobaklabs-k8s

This repo holds helm/helmfile configuration used in the on-prem kubernetes cluster based on Talos Linux.

### Apps

For now, the cluster is on the experiments phase and hosts metal LB for on prem load balancing and some test apps.

### The plan

The plan is to migrate part of my services hosted on the on-prem lab like:
- game servers
- personal projects (mainly test environments)
- AI Stack or its individual components
- new applications

### TODO
The cluster needs:
- more nodes (HA control plane + workers)
- monitoring stack (kube-prometheus stack, maybe loki)
- a storage driver (NFS or Longhorn)
- More test apps/deployments
