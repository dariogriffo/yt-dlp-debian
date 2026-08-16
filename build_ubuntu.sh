YT_DLP_VERSION=$1
BUILD_VERSION=$2

if [ -z "$YT_DLP_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <yt_dlp_version> <build_version>"
    echo "Example: $0 2026.07.04 1"
    exit 1
fi

# yt-dlp ships as a self-contained Python zipapp, so a single Architecture: all
# package covers every Ubuntu architecture (amd64, arm64, armhf, ppc64el,
# riscv64, s390x, ...).
ARCH="all"
YT_DLP_SRC="yt-dlp"

download_upstream() {
    # Clean up any previous download
    rm -rf "$YT_DLP_SRC" || true
    rm -f "${YT_DLP_SRC}.tar.gz" || true

    # The release tarball carries the zipapp, the man page and the shell
    # completions -- everything the package installs.
    if ! wget "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp.tar.gz"; then
        echo "❌ Failed to download yt-dlp $YT_DLP_VERSION"
        return 1
    fi

    if ! tar -xf "${YT_DLP_SRC}.tar.gz"; then
        echo "❌ Failed to extract yt-dlp $YT_DLP_VERSION"
        return 1
    fi

    rm -f "${YT_DLP_SRC}.tar.gz"
    return 0
}

build_packages() {
    echo "Building for architecture: $ARCH"

    if ! download_upstream; then
        return 1
    fi

    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$YT_DLP_VERSION-${BUILD_VERSION}~${dist}_${ARCH}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "yt-dlp-ubuntu-$dist-$ARCH" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg YT_DLP_VERSION="$YT_DLP_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$ARCH" \
            --build-arg YT_DLP_SRC="$YT_DLP_SRC"; then
            echo "❌ Failed to build Docker image for $dist"
            return 1
        fi

        id="$(docker create "yt-dlp-ubuntu-$dist-$ARCH")"
        if ! docker cp "$id:/yt-dlp_$FULL_VERSION.deb" - > "./yt-dlp_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist"
            return 1
        fi

        if ! tar -xf "./yt-dlp_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$YT_DLP_SRC" || true

    echo "✅ Successfully built for $ARCH"
    return 0
}

echo "🚀 Building yt-dlp $YT_DLP_VERSION-$BUILD_VERSION for Ubuntu..."
echo ""

if ! build_packages; then
    exit 1
fi

echo ""
echo "🎉 Ubuntu packages built successfully!"
echo "Generated packages:"
ls -la yt-dlp_*_ubu.deb
