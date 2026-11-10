#!/usr/bin/env bash
#
# install.sh — write a verified OmarchySwitch image to an SD card.
#
# Safety model:
#   * requires --device and --image;
#   * refuses anything that is not a block device;
#   * refuses a device with mounted partitions;
#   * verifies the image checksum when a .sha256 file is present;
#   * requires --yes (or an interactive confirmation);
#   * shows the device model and size before writing.
#
# Usage:
#   sudo ./installer/scripts/install.sh --device /dev/sdX --image FILE [--yes]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

DEVICE=""
IMAGE=""
FORCE=0

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --device) DEVICE="${2:-}"; [[ -n "$DEVICE" ]] || osw_die "--device needs a path"; shift ;;
    --image) IMAGE="${2:-}"; [[ -n "$IMAGE" ]] || osw_die "--image needs a file"; shift ;;
    --force) FORCE=1 ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_root
osw_require_cmds dd sync sha256sum lsblk

[[ -n "$DEVICE" ]] || osw_die "--device is required (e.g. /dev/sdX)"
[[ -n "$IMAGE" ]] || osw_die "--image is required (produced by scripts/build-image.sh)"
[[ -b "$DEVICE" ]] || osw_die "not a block device: $DEVICE"
DEVICE="$(realpath -- "$DEVICE")"
osw_require_file "$IMAGE"
IMAGE="$(realpath -- "$IMAGE")"

osw_step "Target"
lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINT "$DEVICE" >&2
if lsblk -no MOUNTPOINT "$DEVICE" 2>/dev/null | grep -qv '^$'; then
  osw_die "$DEVICE or one of its partitions is mounted. Unmount it first (this script will not force it)."
fi
if [[ -n "$(lsblk -no MOUNTPOINT "${DEVICE}"* 2>/dev/null | tr -d '[:space:]')" ]]; then
  osw_die "a partition of $DEVICE is mounted. Unmount it first."
fi

osw_step "Image"
image_bytes="$(osw_file_bytes "$IMAGE")"
device_bytes="$(blockdev --getsize64 "$DEVICE" 2>/dev/null || echo 0)"
osw_info "$(basename -- "$IMAGE"): $((image_bytes / 1024 / 1024)) MiB"
osw_info "$DEVICE: $((device_bytes / 1024 / 1024)) MiB"
if (( device_bytes > 0 && image_bytes > device_bytes )); then
  osw_die "image is larger than the target device"
fi

sha_file="$IMAGE.sha256"
if [[ -f "$sha_file" ]]; then
  expected="$(awk 'NR==1 {print $1}' "$sha_file")"
  osw_info "verifying SHA-256 (this can take a minute)"
  actual="$(osw_sha256 "$IMAGE")"
  if [[ "$expected" != "$actual" ]]; then
    osw_die "checksum mismatch: image is corrupt or was modified"
  fi
  osw_ok "checksum matches $sha_file"
else
  osw_warn "no .sha256 file next to the image: cannot verify integrity"
  osw_confirm "Continue without checksum verification?"
fi

osw_step "Write"
osw_warn "ALL DATA ON $DEVICE WILL BE DESTROYED"
[[ "$FORCE" == "1" ]] || osw_confirm "Write $(basename -- "$IMAGE") to $DEVICE?"

osw_info "writing (this can take several minutes)"
if ! dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync; then
  osw_die "dd failed: the card may be partially written. Re-run from the start."
fi
sync
osw_ok "write finished"

osw_step "Verify"
# Re-read the first bytes and compare them with the image header. This catches
# a wrong device or an I/O error without re-reading the whole card.
if dd if="$DEVICE" bs=1M count=8 status=none 2>/dev/null | cmp -s - <(dd if="$IMAGE" bs=1M count=8 status=none 2>/dev/null); then
  osw_ok "first 8 MiB match the image"
else
  osw_die "read-back mismatch: do not trust this card"
fi

partprobe "$DEVICE" 2>/dev/null || true
lsblk -o NAME,SIZE,LABEL,FSTYPE "$DEVICE" >&2

cat >&2 <<EOF

Card written.

Next steps:
  1. insert the card in the console,
  2. enter RCM and inject hekate (${HEKATE_RELEASE_URL}),
  3. in hekate choose "More configs..." -> "OmarchySwitch (Erista)".

If the console returns to the hekate menu or stays black, see
docs/06-known-limitations.md before changing the configuration.
EOF
osw_ok "install finished"
