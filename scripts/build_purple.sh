#!/bin/bash
set -e

# 1. Initialize
mkdir -p build && cd build

lb config --apt-indices false \
          --architectures amd64 \
          --distribution jammy \
          --parent-mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
          --parent-mirror-binary "http://archive.ubuntu.com/ubuntu/" \
          --bootstrap-keyring ubuntu-keyring \
          --archive-areas "main restricted universe multiverse" \
          --debian-installer false \
          --iso-publisher "PurpleOS"

# 2. Stable Package List
mkdir -p config/package-lists
cat <<EOF > config/package-lists/desktop.list.chroot
sddm
kde-plasma-desktop
vlc
network-manager
plasma-nm
ark
gwenview
EOF

# 3. Apply Space Black & Amethyst Aesthetics
mkdir -p config/includes.chroot/etc/skel/.config
cat <<EOF > config/includes.chroot/etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOF

# 4. Start the Build
echo "--- Starting the Full OS Build ---"
sudo lb build

# 5. Move the result
if [ -f *.iso ]; then
    mv *.iso ../PurpleOS.iso
else
    # Fallback if name is different
    mv live-image-amd64.hybrid.iso ../PurpleOS.iso || true
fi

cd ..
echo "Build Complete!"
