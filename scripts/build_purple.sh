#!/bin/bash
set -e

# 1. Initialize Live Build
mkdir -p build && cd build
lb config --apt-indices false \
          --architectures amd64 \
          --bootstrap-keyring ubuntu-keyring \
          --archive-areas "main restricted universe multiverse" \
          --debian-installer false \
          --iso-publisher "PurpleOS; http://github.com/mysteriyo789"

# 2. Add the Desktop and Apps
# This tells the builder exactly what to put in the ISO
mkdir -p config/package-lists
cat <<EOF > config/package-lists/desktop.list.chroot
sddm
kde-plasma-desktop
vlc
vivaldi-standalone
network-manager
plasma-nm
EOF

# 3. Apply the Space Black & Amethyst Theme
mkdir -p config/includes.chroot/etc/skel/.config
cat <<EOF > config/includes.chroot/etc/skel/.config/kdeglobals
[General]
ColorScheme=BreezeDark
AccentColor=103,58,183
EOF

# 4. Start the Build
echo "--- Starting the Full OS Build ---"
sudo lb build

# 5. Move the result to the main folder
mv *.iso ../PurpleOS.iso
cd ..
echo "Build Complete!"
