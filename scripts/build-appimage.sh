#!/bin/sh

set -eux

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

BUILD_DIR=$(mktemp -d)

LIB4BN_URL="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME_URL="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
UPINFO="gh-releases-zsync|$(echo "${GITHUB_REPOSITORY}" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# Prepare AppDir
cp -r build/linux/*/release/bundle/. "$BUILD_DIR"/AppDir
cp linux/appimage/interstellar.desktop "$BUILD_DIR"/AppDir
cp assets/icons/logo.png "$BUILD_DIR"/AppDir/interstellar.png
ln -s interstellar.png "$BUILD_DIR"/AppDir/.DirIcon

# Add libraries
wget "$LIB4BN_URL" -O "$BUILD_DIR"/lib4bin
chmod +x "$BUILD_DIR"/lib4bin
xvfb-run -a -- "$BUILD_DIR"/lib4bin l -s -k -e -v -p -d "$BUILD_DIR"/AppDir "$BUILD_DIR"/AppDir/interstellar /usr/lib/*/libGL*
ln -s ../data "$BUILD_DIR"/AppDir/bin/data
ln -s ../lib "$BUILD_DIR"/AppDir/bin/lib
ln -s ../../data "$BUILD_DIR"/AppDir/shared/bin/data
ln -s ../../lib "$BUILD_DIR"/AppDir/shared/bin/lib

# Prepare sharun
ln "$BUILD_DIR"/AppDir/sharun "$BUILD_DIR"/AppDir/AppRun
"$BUILD_DIR"/AppDir/sharun -g

# Make AppImage
wget "$URUNTIME_URL" -O "$BUILD_DIR"/uruntime
chmod +x "$BUILD_DIR"/uruntime
mkdir -p dist

"$BUILD_DIR"/uruntime --appimage-addupdinfo "${UPINFO}"

"$BUILD_DIR"/uruntime --appimage-mkdwarfs -f \
    --set-owner 0 --set-group 0 \
    --no-history --no-create-timestamp \
    --compression zstd:level=22 -S26 -B8 \
    --header "$BUILD_DIR"/uruntime \
    -i "$BUILD_DIR"/AppDir -o dist/interstellar-linux-"$ARCH".AppImage

zsyncmake dist/*.AppImage -u dist/*.AppImage -o "dist/interstellar-linux-${ARCH}.AppImage.zsync"

# Cleanup
rm -r "$BUILD_DIR"
echo "All done!"
