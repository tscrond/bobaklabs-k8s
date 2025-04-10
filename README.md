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

### Talos configuration

For this cluster i used Talos Linux instances on Proxmox - below you will find some commands that were helpful for creating the cluster.

FYI: i followed an official Talos cluster installation guide for []() and [nocloud distributions](https://www.talos.dev/v1.9/talos-guides/install/cloud-platforms/nocloud/).

To create the VMs i used my [cloudinit script](https://raw.githubusercontent.com/tscrond/k3s-lab-toolkit/refs/heads/main/proxmox-scripts/new_vm_cloudinit.sh) from [k3s-lab-toolkit](https://github.com/tscrond/k3s-lab-toolkit).

```zsh
talosctl gen config talos-cluster https://<control_plane_node_ip>:6443 --output-dir _out

talosctl get disks --insecure --nodes <control_plane_node_ip> 
talosctl apply-config --insecure --nodes <control_plane_node_ip> --file _out/controlplane.yaml
talosctl apply-config --insecure --nodes <worker_node_ip> --file _out/worker.yaml

talosctl bootstrap
talosctl kubeconfig . #<- upload kubeconfig file to the main directory of this repo
```
