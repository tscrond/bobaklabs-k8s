#!/bin/bash

master_name="m-talos"
worker_name="w-talos"

ip_prefix="192.168.1."
master_ips=("130" "131" "132")
worker_ips=("133" "134" "135" "136")

master_base_id="500"
worker_base_id="400"

i=0
for ip in "${master_ips[@]}"; do
    vm_id="${master_base_id}${i}"
    ./cloudinit_vm.sh --ip-address "${ip_prefix}${ip}/24" \
        --vm-id "$vm_id" \
        --vm-name "${master_name}-$i" \
        --gateway "192.168.1.1" \
        --ssh-keys "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC48nEoa2rRazXTxZ4anL+6CL2bGXTo6w6XcDpmcd3pE tomasz.skrond@boar.network" \
        --network-bridge "vmbr0" \
        --memory 2048 \
        --cores 2 \
        --disk-size 50 \
        --disk-storage "local-lvm" \
        --iso "talos-nocloud-amd64.iso" \
        --tags "talos,master"
    sleep 5
    echo "args: -cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2" >> /etc/pve/qemu-server/${vm_id}.conf
    ((i+=1))
    qm start ${vm_id}
    sleep 5
done

i=0
for ip in "${worker_ips[@]}"; do
    vm_id="${worker_base_id}${i}"
    ./cloudinit_vm.sh --ip-address "${ip_prefix}${ip}/24" \
        --vm-id "$vm_id" \
        --vm-name "${worker_name}-$i" \
        --gateway "192.168.1.1" \
        --ssh-keys "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC48nEoa2rRazXTxZ4anL+6CL2bGXTo6w6XcDpmcd3pE tomasz.skrond@boar.network" \
        --network-bridge "vmbr0" \
        --memory 2048 \
        --cores 2 \
        --disk-size 200 \
        --disk-storage "local-lvm" \
        --iso "talos-nocloud-amd64.iso" \
        --tags "talos,worker"
    sleep 5
    echo "args: -cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2" >> /etc/pve/qemu-server/${vm_id}.conf
    ((i+=1))
    qm start ${vm_id}
    sleep 5
done

sleep 60

set -eou pipefail
set -x

talosctl gen config talos-cluster https://${ip_prefix}${master_ips[0]}:6443 --output-dir _out

for ip in "${master_ips[@]}"; do
    talosctl apply-config --insecure --nodes "${ip_prefix}${ip}" --file _out/controlplane.yaml
    sleep 60
done

for ip in "${worker_ips[@]}"; do
    talosctl apply-config --insecure --nodes "${ip_prefix}${ip}" --file _out/worker.yaml
    sleep 60
done

export TALOSCONFIG="_out/talosconfig"
talosctl config endpoint "${ip_prefix}${master_ips[0]}"
talosctl config node "${ip_prefix}${master_ips[0]}"
talosctl bootstrap
sleep 120
talosctl kubeconfig .
