#!/bin/bash
set -euo pipefail

YT_DLP_VERSION=$1
BUILD_VERSION=$2

if [ -z "$YT_DLP_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <yt_dlp_version> <build_version>"
    echo "Example: $0 2026.07.04 1"
    exit 1
fi

PACKAGE_NAME="yt-dlp"
ORIG_TARBALL="${PACKAGE_NAME}_${YT_DLP_VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${YT_DLP_VERSION}"

echo "Creating Debian/Ubuntu source packages for yt-dlp ${YT_DLP_VERSION}-${BUILD_VERSION}..."

# Download the upstream release tarball (shared .orig.tar.gz across all
# distributions). It already contains the zipapp, the man page and the shell
# completions, so debian/rules never needs network access.
# It extracts as yt-dlp/, so repack it as yt-dlp-<version>/ for dpkg-source.
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream release tarball from GitHub..."
    wget -q "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp.tar.gz" -O upstream.tar.gz
    rm -rf repack
    mkdir repack
    tar -xf upstream.tar.gz -C repack
    mv "repack/${PACKAGE_NAME}" "repack/${BUILD_DIR}"
    tar -czf "$ORIG_TARBALL" -C repack "$BUILD_DIR"
    rm -rf repack upstream.tar.gz
    echo "  ✅ Created $ORIG_TARBALL"
else
    echo "  ✅ Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local dist=$1
    local FULL_VERSION="${YT_DLP_VERSION}-${BUILD_VERSION}~${dist}"

    echo "  Building source package for ${dist} (${FULL_VERSION})..."

    # Clean and recreate build directory from orig tarball
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate distribution-specific changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF
yt-dlp (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${YT_DLP_VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.gz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ✅ ${FULL_VERSION}"
}

echo ""
echo "Building Debian source packages..."
DEBIAN_DISTS=("bookworm" "trixie" "forky" "sid")
for dist in "${DEBIAN_DISTS[@]}"; do
    build_source_package "$dist"
done

echo ""
echo "Building Ubuntu source packages..."
UBUNTU_DISTS=("jammy" "noble" "questing" "resolute")
for dist in "${UBUNTU_DISTS[@]}"; do
    build_source_package "$dist"
done

echo ""
echo "🎉 Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
