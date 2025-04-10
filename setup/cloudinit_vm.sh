#!/bin/bash

set -eo pipefail

set -x

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script provisions a new virtual machine (VM) with cloud-init on a Proxmox host."
    echo "Ensure that the specified ISO file is a cloud image and is available on the host machine."
    echo ""
    echo "Required options:"
    echo "  --ip-address <IP_ADDRESS>        The IP address to assign to the VM."
    echo "  --vm-id <VM_ID>                  The unique numerical identifier for the VM in Proxmox."
    echo "  --vm-name <VM_NAME>              The name of the VM."
    echo "  --ssh-keys <SSH_KEYS>            Comma-separated list of SSH public keys for VM access."
    echo "  --gateway <GATEWAY>              The network gateway for the VM."
    echo "  --memory <MEMORY>                The amount of RAM (in MB) allocated to the VM."
    echo "  --cores <CORES>                  The number of CPU cores assigned to the VM."
    echo "  --disk-size <DISK_SIZE>          The size of the VM's disk (in GB)."
    echo "  --disk-storage <DISK_STORAGE>    The Proxmox storage location where the disk will be stored."
    echo "  --iso <ISO>                      The path to the cloud-init compatible ISO file."
    echo "  --custom-iso-path <PATH>         The path to a custom folder where ISO images are stored. Default: /var/lib/vz/template/iso"
    echo "  --network-bridge <NETWORK_BRIDGE> The network bridge to attach the VM to."
    echo "  --tags <TAGS>                    Comma-separated list of tags for the VM."
    echo ""
    echo "Important Notes:"
    echo "  - Multiple SSH keys should be separated by commas."
    echo "  - The specified ISO file must be present on the Proxmox host."
    echo "  - The ISO file must be a cloud-init compatible cloud image."
    echo "  - Ensure that the VM ID is unique within the Proxmox environment."
    echo "  - Memory should be specified in MB."
    echo "  - Disk size should be specified in GB."
    echo ""
    echo "Example:"
    echo "  $0 --ip-address 192.168.1.100 --vm-id 101 --vm-name ubuntu-vm \\"
    echo "     --ssh-keys \"ssh-rsa AAAA...,ssh-rsa BBBB...\" --gateway 192.168.1.1 \\"
    echo "     --memory 4096 --cores 2 --disk-size 20 --disk-storage local-lvm \\"
    echo "     --iso /var/lib/vz/template/iso/ubuntu-cloud.img \\"
    echo "     --network-bridge vmbr0 --tags dev,webserver"
    echo ""
    exit 1
}


# Default values
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ip-address) IP_ADDRESS="$2"; shift 2 ;;
        --vm-id) VM_ID="$2"; shift 2 ;;
        --vm-name) VM_NAME="$2"; shift 2 ;;
        --ssh-keys) SSH_KEYS=$(echo "$2" | tr ',' '\n'); shift 2 ;;
        --gateway) GATEWAY="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --cores) CORES="$2"; shift 2 ;;
        --disk-size) DISK_SIZE="$2"; shift 2 ;;
        --disk-storage) DISK_STORAGE="$2"; shift 2 ;;
        --iso) ISO="$2"; shift 2 ;;
        --custom-iso-path) CUSTOM_ISO_PATH="$2"; shift 2 ;;
        --network-bridge) NETWORK_BRIDGE="$2"; shift 2 ;;
        --tags) TAGS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Ensure mandatory parameters are provided
if [ -z "$VM_ID" ] || [ -z "$VM_NAME" ] || [ -z "$SSH_KEYS" ]; then
    usage
fi

IMAGE_FILE="/var/lib/vz/template/iso/$ISO"

if [[ "$CUSTOM_ISO_PATH" != "" ]]; then
    echo "Chosen a custom path for ISO: $CUSTOM_ISO_PATH"
    IMAGE_FILE="$CUSTOM_ISO_PATH/$ISO"
fi

echo "Choosing image from location: $IMAGE_FILE"

# Check for the cloud image
if [ ! -f "$IMAGE_FILE" ]; then
        echo "❌ Error ❌"
        echo "Image file not present, exiting..."
        exit 1
fi

# Create VM
echo "Creating VM $VM_ID..."
qm create "$VM_ID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --net0 virtio,bridge="$NETWORK_BRIDGE"

# Import the cloud image into the chosen storage
qm importdisk "$VM_ID" "$IMAGE_FILE" "$DISK_STORAGE"

# Attach the imported disk as the primary drive
qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 "$DISK_STORAGE":vm-"$VM_ID"-disk-0

# Resize the disk to the desired size
qm resize "$VM_ID" scsi0 "+${DISK_SIZE}G"

# Enable Cloud-Init
qm set "$VM_ID" --ide2 "$DISK_STORAGE":cloudinit
qm set "$VM_ID" --boot c --bootdisk scsi0

# Add all SSH keys to Cloud-Init
# Create a temporary file to store SSH keys
SSH_KEY_FILE="/tmp/sshkeys.pub"
> "$SSH_KEY_FILE"  # Clear the file if it exists

echo "$SSH_KEYS" >> "$SSH_KEY_FILE"

# Apply the SSH keys to the VM
qm set "$VM_ID" --sshkey "$SSH_KEY_FILE"

# Set IP Address
qm set "$VM_ID" --ipconfig0 ip="$IP_ADDRESS",gw="$GATEWAY"

# Apply tags if provided
if [ -n "$TAGS" ]; then
    # Convert the comma-separated tags to space-separated values for Proxmox command
    TAGS_CMD=$(echo "$TAGS" | tr ',' ' ')
    qm set "$VM_ID" -tags "$TAGS_CMD"
fi

# Start VM
qm cloudinit update "$VM_ID"

# Cleanup
rm "$SSH_KEY_FILE"

echo "✅ Cloud-Init VM ($VM_NAME) created with:"
echo "   - CPU: $CORES cores"
echo "   - RAM: $MEMORY MB"
echo "   - Disk: $DISK_SIZE on $DISK_STORAGE"
echo "   - IP Address: $IP_ADDRESS"
echo "   - SSH Keys: Configured"
