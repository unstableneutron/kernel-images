#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

require_in_file() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if ! grep -Fq -- "$pattern" "$ROOT_DIR/$file"; then
        echo "missing: $description" >&2
        echo "  file: $file" >&2
        echo "  pattern: $pattern" >&2
        exit 1
    fi
}

require_in_file images/chromium-headless/image/Dockerfile "ARG UBUNTU_VERSION=22.04" "headless keeps Ubuntu 22.04 as the default base"
require_in_file images/chromium-headful/Dockerfile "ARG UBUNTU_VERSION=22.04" "headful keeps Ubuntu 22.04 as the default base"
require_in_file images/chromium-headless/image/Dockerfile 'FROM docker.io/ubuntu:${UBUNTU_VERSION}' "headless base can opt into Ubuntu 24.04"
require_in_file images/chromium-headful/Dockerfile 'FROM docker.io/ubuntu:${UBUNTU_VERSION}' "headful base can opt into Ubuntu 24.04"

require_in_file images/chromium-headless/image/Dockerfile "ARG CHROMIUM_SNAP_REVISION=" "headless arm64 Chromium snap revision is explicit"
require_in_file images/chromium-headful/Dockerfile "ARG CHROMIUM_SNAP_REVISION=" "headful arm64 Chromium snap revision is explicit"
require_in_file images/chromium-headless/image/Dockerfile 'case "${TARGETARCH:-amd64}" in' "headless browser provider branches on target architecture"
require_in_file images/chromium-headful/Dockerfile 'case "${TARGETARCH:-amd64}" in' "headful browser provider branches on target architecture"
require_in_file images/chromium-headless/image/Dockerfile "/etc/chromium-browser/policies" "headless links snap Chromium policy path"
require_in_file images/chromium-headful/Dockerfile "/etc/chromium-browser/policies" "headful links snap Chromium policy path"

require_in_file images/chromium-headful/Dockerfile "libasound2t64" "headful Ubuntu 24 uses renamed ALSA runtime package"
require_in_file images/chromium-headful/Dockerfile "libatk-bridge2.0-0t64" "headful Ubuntu 24 uses renamed ATK bridge runtime package"
require_in_file images/chromium-headful/Dockerfile "libgtk-3-0t64" "headful Ubuntu 24 uses renamed GTK runtime package"
require_in_file images/chromium-headful/Dockerfile "libvpx9" "headful Ubuntu 24 uses available libvpx runtime package"
require_in_file images/chromium-headful/Dockerfile "netcat-openbsd" "headful Ubuntu 24 uses concrete netcat provider"
require_in_file images/chromium-headful/Dockerfile "gstreamer1.0-omx" "headful keeps Ubuntu 22.04 OMX package only where available"
require_in_file images/chromium-headful/Dockerfile "make patch xorg-dev" "headful xorg-deps installs patch for dummy driver patching"
require_in_file images/chromium-headless/image/Dockerfile "libasound2t64" "headless Ubuntu 24 uses renamed ALSA runtime package"
require_in_file images/chromium-headless/image/Dockerfile "libgtk-3-0t64" "headless Ubuntu 24 uses renamed GTK runtime package"
require_in_file images/chromium-headless/image/Dockerfile "libpango-1.0-0" "headless Ubuntu 24 uses Noble pango runtime package"

require_in_file images/chromium-headless/build-docker.sh "--build-arg \"UBUNTU_VERSION=" "headless build script forwards Ubuntu version"
require_in_file images/chromium-headful/build-docker.sh "--build-arg \"UBUNTU_VERSION=" "headful build script forwards Ubuntu version"

require_in_file shared/envoy/install-proxy.sh "adduser" "Envoy installer installs adduser before envoy package preinst"
require_in_file shared/envoy/install-proxy.sh "netcat-openbsd" "Envoy installer handles Ubuntu 24 netcat package"

echo "Ubuntu 24 arm64 image invariants satisfied"
