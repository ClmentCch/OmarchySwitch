#!/usr/bin/env bash
#
# partition-sd.sh — partition and format an SD card for OmarchySwitch without
# copying any content.
#
# Advanced use only: scripts/build-image.sh does partitioning, formatting and
# content copy in one verified step. Use this script when you need to prepare
# the card first (custom boot size, manual file copy, inspection).
#
# Creates:
#   p1  FAT32  LABEL=<boot label>   (size from config, default 1 GiB)
#   p2  ext4   LABEL=<root label>   (rest of the device, 4.9-compatible)
#
# Usage:
#   sudo ./installer/partition/partition-sd.sh --device /dev/sdX [--boot-size 1GiB] [--yes]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

DEVICE=""
BOOT_SIZE=""

usage() { sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --device) DEVICE="${2:-}"; [[ -n "$DEVICE" ]] || osw_die "--device needs a path"; shift ;;
    --boot-size) BOOT_SIZE="${2:-}"; [[ -n "$BOOT_SIZE" ]] || osw_die "--boot-size needs a value"; shift ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_root
osw_require_cmds parted mkfs.vfat mkfs.ext4 partprobe
[[ -n "$DEVICE" ]] || osw_die "--device is required"
[[ -b "$DEVICE" ]] || osw_die "not a block device: $DEVICE"
DEVICE="$(realpath -- "$DEVICE")"
BOOT_SIZE="${BOOT_SIZE:-$BOOT_PART_SIZE}"

osw_step "Target"
lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINT "$DEVICE" >&2
if lsblk -no MOUNTPOINT "${DEVICE}"* 2>/dev/null | grep -qv '^$'; then
  osw_die "a partition of $DEVICE is mounted; unmount it first"
fi
osw_warn "ALL DATA ON $DEVICE WILL BE DESTROYED"
osw_confirm "Partition and format $DEVICE?"

osw_step "Partition table"
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart boot fat32 1MiB "$BOOT_SIZE"
parted -s "$DEVICE" mkpart root ext4 "$BOOT_SIZE" 100%
partprobe "$DEVICE" 2>/dev/null || true
sleep 1

resolve_part() {
  local base="$1" index="$2"
  if [[ -b "${base}p${index}" ]]; then printf '%s' "${base}p${index}"; else printf '%s' "${base}${index}"; fi
}
BOOT_PART="$(resolve_part "$DEVICE" 1)"
ROOT_PART="$(resolve_part "$DEVICE" 2)"
[[ -b "$BOOT_PART" && -b "$ROOT_PART" ]] || osw_die "cannot resolve new partitions (try partprobe $DEVICE)"

osw_step "Filesystems"
mkfs.vfat -F 32 -n "$BOOT_FS_LABEL" "$BOOT_PART" >/dev/null
osw_ok "$BOOT_PART: FAT32, label $BOOT_FS_LABEL"
mkfs.ext4 -q -L "$ROOT_FS_LABEL" -O ^orphan_file,^metadata_csum_seed -m 1 "$ROOT_PART"
osw_ok "$ROOT_PART: ext4, label $ROOT_FS_LABEL, 4.9-compatible features"

lsblk -o NAME,SIZE,LABEL,FSTYPE "$DEVICE" >&2
cat >&2 <<EOF

Partitioning done. Nothing was copied.

To populate manually:
  mount $BOOT_PART /mnt && cp -a build/output/boot/. /mnt/ && umount /mnt
  mount $ROOT_PART /mnt && tar -C build/output/rootfs -cf - . | tar -C /mnt -xpf - && umount /mnt

Remember /etc/fstab must reference LABEL=$ROOT_FS_LABEL and LABEL=$BOOT_FS_LABEL.
EOF
osw_ok "partition-sd finished"
