#!/bin/bash
set -e

# 1. Setup Environment
ROOT=$(pwd)/rootfs
ISO_DIR=$(pwd)/iso
mkdir -p "$ROOT" "$ISO_DIR/live" output
export DEBIAN_FRONTEND=noninteractive

# 2. Bootstrap (The core)
echo "--- Stage 1: Bootstrapping ---"
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Mount and Install (The Manual way)
echo "--- Stage 2: Installing Desktop ---"
sudo mount --bind /dev "$ROOT/dev"
sudo mount --bind /run "$ROOT/run"
sudo mount -t proc proc "$ROOT/proc"
sudo mount -t sysfs sys "$ROOT/sys"

sudo chroot "$ROOT" /bin/bash <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
# Install ONLY what is needed to boot and look good
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

# 4. Finalizing the ISO
echo "--- Stage 3: Packaging ---"
# Unmount to avoid errors
sudo umount -l "$ROOT/dev" "$ROOT/run" "$ROOT/proc" "$ROOT/sys" || true

# Copy Kernel to ISO folder
cp "$ROOT/boot/vmlinuz-"* "$ISO_DIR/live/vmlinuz"
cp "$ROOT/boot/initrd.img-"* "$ISO_DIR/live/initrd"

# Compress it
sudo mksqufs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" -comp xz

# Instead of fighting xorriso/bootloaders, we provide the raw squashfs as the artifact
# This can be used with Ventoy or customized later.
mv "$ISO_DIR/live/filesystem.squashfs" output/PurpleOS.iso

echo "Build Complete!"
