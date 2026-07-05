#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORKFLOW_DIR="$ROOT_DIR/.github/workflows"

require_in_file() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if ! grep -Fq -- "$pattern" "$file"; then
        echo "missing: $description" >&2
        echo "  file: $file" >&2
        echo "  pattern: $pattern" >&2
        exit 1
    fi

    echo "ok: $description"
}

require_not_in_file() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if grep -Fq -- "$pattern" "$file"; then
        echo "unexpected: $description" >&2
        echo "  file: $file" >&2
        echo "  pattern: $pattern" >&2
        exit 1
    fi

    echo "ok: $description"
}

require_in_workflows() {
    local pattern="$1"
    local description="$2"

    if ! grep -RFq -- "$pattern" "$WORKFLOW_DIR"; then
        echo "missing: $description" >&2
        echo "  dir: .github/workflows" >&2
        echo "  pattern: $pattern" >&2
        exit 1
    fi

    echo "ok: $description"
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

"$ROOT_DIR/scripts/generate-smolvm-pack-smolfile.sh" \
    chromium-headless \
    ghcr.io/kernel-images/chromium-headless:test \
    linux/amd64 \
    "$tmpdir/headless.smolfile"

"$ROOT_DIR/scripts/generate-smolvm-pack-smolfile.sh" \
    chromium-headful \
    ghcr.io/kernel-images/chromium-headful:test \
    linux/arm64 \
    "$tmpdir/headful.smolfile"

require_in_file "$tmpdir/headless.smolfile" "--no-zygote" "headless Smolfile enables fork-ready Chromium"
require_in_file "$tmpdir/headless.smolfile" "/chromium/flags" "headless Smolfile writes runtime flag overlay"
require_not_in_file "$tmpdir/headless.smolfile" "CHROMIUM_FLAGS=" "headless Smolfile does not duplicate wrapper defaults"
require_in_file "$ROOT_DIR/server/cmd/wrapper/chromium.go" "--no-sandbox" "headless wrapper keeps no-sandbox default"
require_in_file "$ROOT_DIR/server/cmd/wrapper/chromium.go" "--disable-dev-shm-usage" "headless wrapper keeps dev-shm default"
require_in_file "$tmpdir/headful.smolfile" "--no-zygote" "headful Smolfile enables fork-ready Chromium"
require_in_file "$tmpdir/headful.smolfile" "--no-sandbox" "headful Smolfile enables root-safe Chromium"
require_in_file "$tmpdir/headful.smolfile" "--disable-dev-shm-usage" "headful Smolfile keeps dev-shm default"

require_in_workflows "ghcr.io" "workflow publishes GHCR refs"
require_in_workflows "packages: write" "workflow has package write permission"
require_in_workflows "ubuntu-24.04-arm" "workflow has Ubuntu 24.04 arm runner"
require_in_workflows "linux/amd64" "workflow includes linux/amd64 platform"
require_in_workflows "linux/arm64" "workflow includes linux/arm64 platform"
require_in_workflows "https://smolmachines.com/install.sh" "workflow installs smolvm"
require_in_workflows "/dev/kvm" "workflow checks KVM availability for smolvm packing"
require_in_workflows "smolvm pack create" "workflow creates smolvm packs"
require_in_workflows "smolvm pack push" "workflow pushes smolvm packs"
require_in_workflows "docker buildx imagetools inspect" "workflow inspects cross-arch smolvm packs"
require_in_workflows "kernel-smolmachines/" "workflow uses kernel-smolmachines package path"

echo "Ubuntu 24 CI invariants satisfied"
