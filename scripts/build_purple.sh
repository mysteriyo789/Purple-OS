#!/bin/bash
set -e

# 1. Setup Workspace
mkdir -p work/rootfs output
ROOT=$(pwd)/work/rootfs
export DEBIAN_FRONTEND=noninteractive

# 2. Base System
echo "--- Stage 1: Base System ---"
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Fixing Network for Chroot
sudo cp /etc/resolv.conf "$ROOT"/etc/resolv.conf

# 4. Force Installation of KDE and Apps
echo "--- Stage 2: Heavy Installation ---"
# We run these as individual commands so we can see exactly where it stops
sudo chroot "$ROOT" apt-get update
sudo chroot "$ROOT" apt-get install -y sddm kde-plasma-desktop vlc vivaldi-standalone flatpak plasma-nm network-manager

# --- THE CHECK ---
# If this folder doesn't exist, the desktop didn't install.
if [ ! -d "$ROOT/usr/share/plasma" ]; then
  echo "ERROR: Desktop files not found. Installation failed."
  exit 1
fi

# 5. Apply Aesthetics
echo "--- Stage 3: Aesthetics ---"
sudo mkdir -p "$ROOT/etc/skel/.config"
sudo bash -c "cat <<EOT > $ROOT/etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOT"

# 6. Compressing (The "Wait" Stage)
echo "--- Stage 4: High Compression ---"
sudo mksquashfs "$ROOT" output/PurpleOS.iso -comp xz
