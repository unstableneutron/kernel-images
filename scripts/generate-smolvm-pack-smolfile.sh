#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage: scripts/generate-smolvm-pack-smolfile.sh <chromium-headless|chromium-headful> <image-ref> <linux/amd64|linux/arm64> <output-smolfile>
EOF
}

die_usage() {
    echo "error: $1" >&2
    usage
    exit 1
}

reject_single_quote() {
    local name="$1"
    local value="$2"

    case "$value" in
        *"'"*) die_usage "$name must not contain single quotes" ;;
    esac
}

join_flags() {
    local IFS=' '
    printf '%s' "$*"
}

json_flags() {
    local first=true
    local flag

    printf '{"flags":['
    for flag in "$@"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ','
        fi
        printf '"%s"' "$flag"
    done
    printf ']}'
}

if [[ "$#" -ne 4 ]]; then
    die_usage "expected 4 arguments, got $#"
fi

image_type="$1"
image_ref="$2"
platform="$3"
output_smolfile="$4"

case "$image_type" in
    chromium-headless | chromium-headful) ;;
    *) die_usage "image type must be chromium-headless or chromium-headful" ;;
esac

case "$platform" in
    linux/amd64 | linux/arm64) ;;
    *) die_usage "platform must be linux/amd64 or linux/arm64" ;;
esac

reject_single_quote "image-ref" "$image_ref"
reject_single_quote "platform" "$platform"

if [[ -z "$image_ref" ]]; then
    die_usage "image-ref must not be empty"
fi

if [[ -z "$output_smolfile" ]]; then
    die_usage "output-smolfile must not be empty"
fi

case "$image_type" in
    chromium-headless)
        chromium_flags=(
            "--no-zygote"
        )
        ;;
    chromium-headful)
        chromium_flags=(
            "--user-data-dir=/home/kernel/user-data"
            "--disable-dev-shm-usage"
            "--disable-gpu"
            "--start-maximized"
            "--disable-software-rasterizer"
            "--remote-allow-origins=*"
            "--no-sandbox"
            "--no-zygote"
        )
        ;;
esac

chromium_flags_json=$(json_flags "${chromium_flags[@]}")
chromium_flags_json_for_shell=${chromium_flags_json//\"/\\\"}
entrypoint_script="mkdir -p /chromium && printf %s \"${chromium_flags_json_for_shell}\" > /chromium/flags && exec /wrapper"
chromium_flags_string=$(join_flags "${chromium_flags[@]}")
reject_single_quote "Chromium flags" "$chromium_flags_string"
reject_single_quote "entrypoint script" "$entrypoint_script"

cat > "$output_smolfile" <<EOF
image = '$image_ref'
entrypoint = ['/bin/bash', '-lc', '$entrypoint_script']
cpus = 4
memory = 8192
net = true
env = [
  'KERNEL_SMOLVM_FORKREADY=true',
]

[artifact]
oci_platform = '$platform'
EOF
