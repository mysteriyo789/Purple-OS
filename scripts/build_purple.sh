#!/bin/bash
set -e

# 1. Setup Workspace
mkdir -p work/rootfs output
ROOT=$(pwd)/work/rootfs
export DEBIAN_FRONTEND=noninteractive

# 2. Base System
echo "--- Stage 1: Base System ---"
sudo debootstrap --arch amd64 jammy "$ROOT" http://archive.ubuntu.com/ubuntu/

# 3. Customization
echo "--- Stage 2: Installing Desktop (The Heavy Part) ---"
sudo chroot "$ROOT" /bin/bash <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update

# We install the core desktop first. 
# If this fails, the whole build will now stop correctly.
apt-get install -y sddm kde-plasma-desktop

# Install your general-use apps
apt-get install -y vlc vivaldi-standalone flatpak plasma-discover-backend-flatpak \
                   plasma-nm network-manager fonts-inter-variable

# Apply Space Black & Amethyst Aesthetics
mkdir -p /etc/skel/.config
cat <<EOT > /etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOT

systemctl enable sddm
apt-get clean
EOF

# 4. Finalizing
echo "--- Stage 3: Compressing (This should take a long time) ---"
# We use 'xz' here to ensure the file is as small as possible but still 'real'
sudo mksquashfs "$ROOT" output/PurpleOS.iso -comp xz -Xbcj x86

echo "--- BUILD COMPLETE ---"
