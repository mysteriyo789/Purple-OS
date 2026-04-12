#!/bin/bash
set -e

# 1. Initialize Live Build with specific Ubuntu Jammy settings
mkdir -p build && cd build

# We MUST specify --distribution jammy and the correct parent mirror
lb config --apt-indices false \
          --architectures amd64 \
          --distribution jammy \
          --parent-mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
          --parent-mirror-binary "http://archive.ubuntu.com/ubuntu/" \
          --bootstrap-keyring ubuntu-keyring \
          --archive-areas "main restricted universe multiverse" \
          --debian-installer false \
          --iso-publisher "PurpleOS"

# 2. Add the Desktop and Apps
mkdir -p config/package-lists
cat <<EOF > config/package-lists/desktop.list.chroot
sddm
kde-plasma-desktop
vlc
vivaldi-standalone
network-manager
plasma-nm
EOF

# 3. Apply Aesthetics
mkdir -p config/includes.chroot/etc/skel/.config
cat <<EOF > config/includes.chroot/etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOF

# 4. Start the Build
echo "--- Starting the Full OS Build for Jammy ---"
sudo lb build

# 5. Move the result
# Live-build usually names the file 'live-image-amd64.hybrid.iso'
if [ -f *.iso ]; then
    mv *.iso ../PurpleOS.iso
else
    echo "ISO generation failed"
    exit 1
fi

cd ..
echo "Build Complete!"
