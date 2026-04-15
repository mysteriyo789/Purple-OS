#!/bin/bash
set -e

# 1. Setup Environment
# We define our working directories clearly
ROOT=$(pwd)/rootfs
ISO_DIR=$(pwd)/iso
mkdir -p "$ROOT" "$ISO_DIR/live" output
export DEBIAN_FRONTEND=noninteractive

# 2. Stage 1: Core System (The Foundation)
echo "--- Stage 1: Bootstrapping Ubuntu Jammy ---"
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Stage 2: Desktop & Apps (The Purple Core)
echo "--- Stage 2: Installing Desktop & Drivers ---"
# Mount system directories so the 'chroot' environment has internet and hardware access
sudo mount --bind /dev "$ROOT/dev"
sudo mount --bind /run "$ROOT/run"
sudo mount -t proc proc "$ROOT/proc"
sudo mount -t sysfs sys "$ROOT/sys"

sudo chroot "$ROOT" /bin/bash <<EOF
export DEBIAN_FRONTEND=noninteractive

# Unlock all Ubuntu repositories (Universe/Multiverse)
printf "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse\n" > /etc/apt/sources.list
printf "deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse\n" >> /etc/apt/sources.list
printf "deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse\n" >> /etc/apt/sources.list

apt-get update

# Install Kernel, Desktop (KDE), and Utilities
# This is the 'heavy' part—wait for the downloads to finish
apt-get install -y --no-install-recommends \
    linux-image-generic initramfs-tools casper \
    sddm kde-plasma-desktop plasma-nm network-manager \
    vlc ark gwenview

# Apply the Space Black & Amethyst Aesthetics (Purple Accent)
mkdir -p /etc/skel/.config
cat <<EOT > /etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOT

# Cleanup to keep the ISO size down
apt-get clean
EOF

# 4. Stage 3: Packaging (The Final ISO)
echo "--- Stage 3: Packaging for Hardware ---"
# Unmount safely
sudo umount -l "$ROOT/dev" "$ROOT/run" "$ROOT/proc" "$ROOT/sys" || true

# Identify and copy the kernel files for booting
# Using direct paths to avoid previous wildcard/syntax errors
sudo cp "$ROOT"/boot/vmlinuz-*-generic "$ISO_DIR/live/vmlinuz"
sudo cp "$ROOT"/boot/initrd.img-*-generic "$ISO_DIR/live/initrd"

# Ensure the output directory is ready
sudo mkdir -p output
sudo rm -f output/PurpleOS.iso

# High-ratio XZ compression (This is where Build #11 took its time)
# It turns 3GB of files into a compact, portable ISO
sudo mksquashfs "$ROOT" output/PurpleOS.iso -comp xz

echo "------------------------------------------"
echo "Build Complete! File is at: output/PurpleOS.iso"
echo "------------------------------------------"
