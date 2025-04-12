# bobaklabs-k8s

This repo holds helm/helmfile configuration used in the on-prem kubernetes cluster based on Talos Linux.

## Apps

For now, the cluster is on the experiments phase and hosts metal LB for on prem load balancing and some test apps.

## The plan

The plan is to migrate part of my services hosted on the on-prem lab like:

- game servers
- personal projects (mainly test environments)
- AI Stack or its individual components
- new applications

## TODO

The cluster needs:

- More nodes (HA control plane + workers) ✅
- Monitoring stack (kube-prometheus stack, maybe loki) ✅
- A storage driver (NFS or Longhorn) ✅
- Cert Manager ✅
- Sealed Secrets ✅
- Traefik Load Balancer
  - installation ✅
  - configuration
- More test apps/deployments:
    - n8n
    - minecraft server
    - dropper app

## Talos configuration

For this cluster i used Talos Linux instances on Proxmox - below you will find some commands that were helpful for creating the cluster.

FYI: i followed an official Talos cluster installation guide for []() and [nocloud distributions](https://www.talos.dev/v1.9/talos-guides/install/cloud-platforms/nocloud/).

To create the VMs i used my [cloudinit script](https://raw.githubusercontent.com/tscrond/k3s-lab-toolkit/refs/heads/main/proxmox-scripts/new_vm_cloudinit.sh) from [k3s-lab-toolkit](https://github.com/tscrond/k3s-lab-toolkit).


### Configuring a Talos Linux cluster
```zsh
talosctl gen config talos-cluster https://<control_plane_node_ip>:6443 --output-dir _out

talosctl get disks --insecure --nodes <control_plane_node_ip> 
talosctl apply-config --insecure --nodes <control_plane_node_ip> --file _out/controlplane.yaml
talosctl apply-config --insecure --nodes <worker_node_ip> --file _out/worker.yaml

talosctl bootstrap
talosctl kubeconfig . #<- upload kubeconfig file to the main directory of this repo
```

### Customizing talos base ISO

Use customized configuration with iscsi tools (for longhorn storage driver)
```yaml
# talos/bare-metal.yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
```

Generate an talos factory image ID:
```zsh
curl -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics
```

Upgrade VMs (for machines already running already in the cluster):
```zsh
talosctl upgrade --talosconfig=./_out/talosconfig --nodes <nodes_list_comma_delimited> --image factory.talos.dev/installer/<iso_id>:v1.9.5
```

### Patching Talos nodes for Longhorn storage

Patch for longhorn volumes:
```yaml
# talos/longhorn-volume-patch.yaml
machine:
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
```

Patch for data engine kernel modules:
```yaml
# talos/longhorn-data-engine-patch.yaml
machine:
  sysctls:
    vm.nr_hugepages: "1024"
  kernel:
    modules:
      - name: nvme_tcp
      - name: vfio_pci
```

Use the following commands to patch:
```zsh
talosctl patch mc -n <worker_nodes> --patch @longhorn-volume-patch.yaml
talosctl patch mc -n <worker_nodes> --patch @longhorn-data-engine-patch.yaml
```
