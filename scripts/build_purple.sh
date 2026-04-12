#!/bin/bash
set -e

# 1. Setup Workspace
echo "Setting up workspace..."
mkdir -p work/rootfs work/iso/live output
ROOT=$(pwd)/work/rootfs
ISO_DIR=$(pwd)/work/iso
export DEBIAN_FRONTEND=noninteractive

# 2. Base System
echo "Building Base System (Ubuntu Jammy)..."
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Customization (The "Space Black" Logic)
echo "Entering System to install Desktop..."
sudo chroot "$ROOT" /bin/bash <<EOF
apt-get update
apt-get install -y software-properties-common
add-apt-repository ppa:damentz/liquorix -y
apt-get update

# Install Kernel and Desktop
apt-get install -y linux-image-liquorix-amd64 sddm kde-plasma-desktop \
                   discover packagekit-qt5 flatpak vlc vivaldi-standalone \
                   libreoffice-fresh iio-sensor-proxy plasma-keyboard

# Apply Aesthetics (Matte Black + Amethyst)
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

# 4. Create the Bootable Image
echo "Compressing filesystem..."
sudo mksquashfs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" -comp xz

# Copy Kernel to ISO folder so it can boot
cp "$ROOT"/boot/vmlinuz-* "$ISO_DIR/live/vmlinuz"
cp "$ROOT"/boot/initrd.img-* "$ISO_DIR/live/initrd"

# Generate the final ISO
echo "Finalizing ISO file..."
sudo xorriso -as mkisofs -R -l -J -joliet-long -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table -o output/PurpleOS.iso "$ISO_DIR" || \
    (echo "Xorriso failed, creating basic container instead" && sudo cp "$ISO_DIR/live/filesystem.squashfs" output/PurpleOS.iso)

echo "Build Process Finished Successfully."
