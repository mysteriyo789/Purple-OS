#!/bin/bash
set -e

# 1. Setup Environment
ROOT=$(pwd)/rootfs
ISO_DIR=$(pwd)/iso
mkdir -p "$ROOT" "$ISO_DIR/live" output
export DEBIAN_FRONTEND=noninteractive

# 2. Bootstrap
echo "--- Stage 1: Bootstrapping ---"
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Mount and Install
echo "--- Stage 2: Installing Desktop ---"
sudo mount --bind /dev "$ROOT/dev"
sudo mount --bind /run "$ROOT/run"
sudo mount -t proc proc "$ROOT/proc"
sudo mount -t sysfs sys "$ROOT/sys"

sudo chroot "$ROOT" /bin/bash <<EOF
export DEBIAN_FRONTEND=noninteractive

# FORCE ENABLE REPOSITORIES (The Fix for 'Package not found')
printf "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse\n" > /etc/apt/sources.list
printf "deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse\n" >> /etc/apt/sources.list
printf "deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse\n" >> /etc/apt/sources.list

apt-get update

# Install Kernel and Desktop (This will take 15-30 mins)
apt-get install -y --no-install-recommends \
    linux-image-generic initramfs-tools casper \
    sddm kde-plasma-desktop plasma-nm network-manager \
    vlc ark gwenview

# Aesthetic Setup
mkdir -p /etc/skel/.config
cat <<EOT > /etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOT

apt-get clean
EOF

# 4. Finalizing
echo "--- Stage 3: Packaging ---"
sudo umount -l "$ROOT/dev" "$ROOT/run" "$ROOT/proc" "$ROOT/sys" || true

# Copy Kernel files (Robust matching)
KERNEL_IMG=\$(ls "$ROOT/boot/vmlinuz-"* | head -n 1)
INITRD_IMG=\$(ls "$ROOT/boot/initrd.img-"* | head -n 1)

cp "\$KERNEL_IMG" "$ISO_DIR/live/vmlinuz"
cp "\$INITRD_IMG" "$ISO_DIR/live/initrd"

# Fixed: mksquashfs command
sudo mksquashfs "$ROOT" output/PurpleOS.iso -comp xz

echo "Build Complete!"
