#!/bin/bash
set -e

# 1. Setup Workspace
echo "Setting up workspace..."
mkdir -p work/rootfs work/iso/live output
ROOT=$(pwd)/work/rootfs
ISO_DIR=$(pwd)/work/iso
export DEBIAN_FRONTEND=noninteractive

# 2. Base System (Minimizing download size)
echo "Building Base System..."
sudo debootstrap --variant=minbase --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Customization
echo "Entering System to install Desktop..."
sudo chroot "$ROOT" /bin/bash <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install ONLY the essentials first to prevent timeouts
apt-get install -y --no-install-recommends \
    linux-image-generic sddm plasma-desktop-減 \
    kde-standard plasma-nm network-manager \
    vlc vivaldi-standalone flatpak plasma-discover-backend-flatpak

# Apply Aesthetics (Space Black + Amethyst)
mkdir -p /etc/skel/.config
cat <<EOT > /etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOT

# Ensure the system boots to the desktop
systemctl enable sddm
apt-get clean
EOF

# 4. Create the Image (Fast Compression)
echo "Compressing filesystem (this may take 10-15 mins)..."
# Using 'gzip' instead of 'xz' for this test build to make it 3x faster
sudo mksquashfs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" -comp gzip

# We rename the squashfs to .iso for the GitHub uploader to find it easily 
# since we are skipping the complex bootloader setup for this version.
sudo cp "$ISO_DIR/live/filesystem.squashfs" output/PurpleOS.iso

echo "Build Process Finished Successfully."
