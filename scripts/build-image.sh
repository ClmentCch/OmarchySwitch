#!/usr/bin/env bash
#
# build-image.sh — assemble a bootable SD image (or write directly to a card)
# from a prepared rootfs and the hekate boot tree.
#
# Layout produced (GPT):
#   p1  FAT32  LABEL=OMARCHYSW  bootloader/, switchroot/omarchyswitch/
#   p2  ext4   LABEL=OSWITCH    Arch Linux ARM root filesystem
#
# The ext4 filesystem is created with orphan_file and metadata_csum_seed
# disabled, because the Switchroot L4T 4.9 kernel cannot mount features it
# does not know. This is a hard requirement, not a preference.
#
# Safety: writing to a block device requires --device plus --yes, refuses any
# device with mounted partitions, and never runs mkfs on a partition it did
# not create in this same invocation.
#
# Usage:
#   sudo ./scripts/build-image.sh --rootfs build/output/rootfs --output out.img
#   sudo ./scripts/build-image.sh --rootfs ... --device /dev/sdX --yes
#
# Options:
#   --rootfs DIR      Prepared rootfs (mandatory).
#   --boot-tree DIR  hekate staging tree (default build/output/boot).
#   --output FILE    Image file to create.
#   --device DEV     Write to a block device instead of a file.
#   --size SIZE      Image size for --output (default 16G).
#   --keep-going     Continue even if optional components are missing.
#   --yes            Required for --device.
#   -h, --help       This help.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ROOTFS=""
BOOT_TREE=""
OUTPUT=""
DEVICE=""
IMAGE_SIZE_ARG=""
KEEP_GOING=0

usage() { sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --rootfs) ROOTFS="${2:-}"; [[ -n "$ROOTFS" ]] || osw_die "--rootfs needs a directory"; shift ;;
    --boot-tree) BOOT_TREE="${2:-}"; [[ -n "$BOOT_TREE" ]] || osw_die "--boot-tree needs a directory"; shift ;;
    --output) OUTPUT="${2:-}"; [[ -n "$OUTPUT" ]] || osw_die "--output needs a file"; shift ;;
    --device) DEVICE="${2:-}"; [[ -n "$DEVICE" ]] || osw_die "--device needs a path"; shift ;;
    --size) IMAGE_SIZE_ARG="${2:-}"; [[ -n "$IMAGE_SIZE_ARG" ]] || osw_die "--size needs a value"; shift ;;
    --keep-going) KEEP_GOING=1 ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_root
osw_require_cmds parted mkfs.ext4 mkfs.vfat mount umount sha256sum

[[ -n "$ROOTFS" ]] || osw_die "--rootfs is required"
ROOTFS="$(realpath -m -- "$ROOTFS")"
osw_require_dir "$ROOTFS"
osw_require_aarch64_tree "$ROOTFS"
BOOT_TREE="$(realpath -m -- "${BOOT_TREE:-$(osw_boot_tree)}")"
osw_require_dir "$BOOT_TREE"
IMAGE_SIZE_ARG="${IMAGE_SIZE_ARG:-$IMAGE_SIZE}"

if [[ -n "$OUTPUT" && -n "$DEVICE" ]]; then
  osw_die "choose --output (image file) or --device (block device), not both"
fi
if [[ -z "$OUTPUT" && -z "$DEVICE" ]]; then
  osw_die "one of --output or --device is required"
fi

osw_start_log "build-image"

osw_step "Preflight"
armed=0
for f in bootloader/hekate_ipl.ini bootloader/ini/omarchyswitch-erista.ini; do
  if [[ -e "$BOOT_TREE/$f" ]]; then
    osw_ok "boot tree: $f"
  else
    osw_warn "boot tree is missing $f"
    armed=1
  fi
done
if [[ ! -f "$BOOT_TREE$SWITCHROOT_BOOT_PREFIX/uImage" ]]; then
  osw_warn "no kernel at $SWITCHROOT_BOOT_PREFIX/uImage in the boot tree"
  armed=1
fi
if [[ ! -d "$ROOTFS/usr/lib/modules" ]] || osw_dir_is_empty "$ROOTFS/usr/lib/modules"; then
  osw_warn "rootfs has no kernel modules: Wi-Fi, Bluetooth, audio and Joy-Con will be dead"
  armed=1
fi
if (( armed == 1 )); then
  if (( KEEP_GOING )); then
    osw_warn "--keep-going: building an image that will probably not boot"
  else
    osw_die "refusing to build an image with missing boot components.
Run scripts/integrate-switchroot.sh first, or pass --keep-going for a
non-bootable image used for tests."
  fi
fi

# --- Target -----------------------------------------------------------------
TARGET=""
if [[ -n "$DEVICE" ]]; then
  [[ -b "$DEVICE" ]] || osw_die "not a block device: $DEVICE"
  DEVICE="$(realpath -- "$DEVICE")"
  if lsblk -no MOUNTPOINT "$DEVICE" 2>/dev/null | grep -qv '^$'; then
    osw_die "$DEVICE or one of its partitions is mounted. Unmount everything first."
  fi
  osw_warn "ALL DATA on $DEVICE WILL BE DESTROYED"
  lsblk -o NAME,SIZE,MODEL,TYPE "$DEVICE" >&2 || true
  osw_confirm "Erase $DEVICE and write OmarchySwitch?"
  TARGET="$DEVICE"
else
  OUTPUT="$(realpath -m -- "$OUTPUT")"
  if [[ -e "$OUTPUT" ]]; then
    osw_confirm "Overwrite existing image $OUTPUT?"
    rm -f -- "$OUTPUT"
  fi
  osw_ensure_dir "$(dirname -- "$OUTPUT")"
  osw_info "creating sparse image of $IMAGE_SIZE_ARG: $OUTPUT"
  truncate -s "$IMAGE_SIZE_ARG" "$OUTPUT"
  TARGET="$OUTPUT"
fi

# --- Partitioning -----------------------------------------------------------
osw_step "Partition table (GPT)"
parted -s "$TARGET" mklabel gpt
parted -s "$TARGET" mkpart boot fat32 1MiB "$BOOT_PART_SIZE"
parted -s "$TARGET" mkpart root ext4 "$BOOT_PART_SIZE" 100%
if [[ -n "$DEVICE" ]]; then
  partprobe "$TARGET" 2>/dev/null || true
  sleep 2
fi
osw_ok "partitions: p1 fat32 (${BOOT_PART_SIZE}), p2 ext4 (rest)"

# Resolve partition device nodes (loop devices need -P, real disks need the
# kernel to re-read the table).
resolve_parts() {
  local base="$1"
  local boot="" root=""
  for _ in $(seq 1 20); do
    if [[ -b "${base}p1" && -b "${base}p2" ]]; then
      boot="${base}p1"; root="${base}p2"; break
    fi
    if [[ -b "${base}1" && -b "${base}2" ]]; then
      boot="${base}1"; root="${base}2"; break
    fi
    sleep 0.5
  done
  printf '%s\t%s' "$boot" "$root"
}

LOOP_DEV=""
MOUNT_DIR=""
cleanup_image() {
  set +e
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    umount "$MOUNT_DIR/boot" 2>/dev/null
    umount "$MOUNT_DIR" 2>/dev/null
    rmdir "$MOUNT_DIR" 2>/dev/null
  fi
  if [[ -n "$LOOP_DEV" ]]; then
    losetup -d "$LOOP_DEV" 2>/dev/null
  fi
}
trap 'cleanup_image; osw_cleanup' EXIT

if [[ -n "$OUTPUT" ]]; then
  LOOP_DEV="$(losetup --find --show --partscan "$OUTPUT")"
  [[ -n "$LOOP_DEV" ]] || osw_die "losetup failed for $OUTPUT"
  osw_info "loop device: $LOOP_DEV"
  read -r BOOT_PART ROOT_PART <<<"$(resolve_parts "$LOOP_DEV")"
else
  read -r BOOT_PART ROOT_PART <<<"$(resolve_parts "$TARGET")"
fi
[[ -b "$BOOT_PART" ]] || osw_die "cannot resolve the boot partition device"
[[ -b "$ROOT_PART" ]] || osw_die "cannot resolve the root partition device"

# --- Filesystems ------------------------------------------------------------
osw_step "Filesystems"
mkfs.vfat -F 32 -n "$BOOT_FS_LABEL" "$BOOT_PART" >/dev/null
osw_ok "mkfs.vfat -n $BOOT_FS_LABEL on $BOOT_PART"
# The L4T 4.9 kernel cannot mount orphan_file or metadata_csum_seed.
mkfs.ext4 -q -L "$ROOT_FS_LABEL" -O ^orphan_file,^metadata_csum_seed -m 1 "$ROOT_PART"
osw_ok "mkfs.ext4 -L $ROOT_FS_LABEL (legacy-compatible features) on $ROOT_PART"

# --- Populate ---------------------------------------------------------------
osw_step "Populating"
MOUNT_DIR="$(mktemp -d)"
mount "$ROOT_PART" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot"
mount "$BOOT_PART" "$MOUNT_DIR/boot"

osw_info "copying the boot tree"
cp -a -- "$BOOT_TREE/." "$MOUNT_DIR/boot/"
osw_info "copying the root filesystem (this takes a while)"
if ! tar -C "$ROOTFS" -cf - . | tar -C "$MOUNT_DIR" -xpf -; then
  osw_die "root filesystem copy failed"
fi

# fstab is generated here so labels always match what was just created.
cat > "$MOUNT_DIR/etc/fstab" <<EOF
# OmarchySwitch - generated by build-image.sh
# Partitions are addressed by label: device names move between SD and eMMC.
LABEL=$BOOT_FS_LABEL  /boot  vfat  defaults,noatime,nofail  0 2
LABEL=$ROOT_FS_LABEL  /      ext4  defaults,noatime         0 1
EOF
osw_ok "/etc/fstab written (LABEL=$ROOT_FS_LABEL on /)"

# Marker used by the Switchroot initramfs.
if [[ ! -f "$MOUNT_DIR/etc/switchroot_version.conf" ]]; then
  printf 'switchroot_version=%s\n' "$SWITCHROOT_VERSION_FILE_VALUE" > "$MOUNT_DIR/etc/switchroot_version.conf"
fi

sync
osw_info "unmounting"
umount "$MOUNT_DIR/boot"
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
MOUNT_DIR=""

if [[ -n "$LOOP_DEV" ]]; then
  losetup -d "$LOOP_DEV"
  LOOP_DEV=""
fi

# --- Verify -----------------------------------------------------------------
osw_step "Verification"
if [[ -n "$OUTPUT" ]]; then
  fsck.ext4 -fn "$OUTPUT" >/dev/null 2>&1 || osw_warn "e2fsck could not check the image directly (expected for a GPT image); mount it to verify"
  bytes="$(osw_file_bytes "$OUTPUT")"
  digest="$(osw_sha256 "$OUTPUT")"
  osw_ok "image: $OUTPUT"
  osw_info "size: $((bytes / 1024 / 1024)) MiB"
  osw_info "sha256: $digest"
  printf '%s  %s\n' "$digest" "$(basename -- "$OUTPUT")" > "$OUTPUT.sha256"
  osw_ok "checksum written: $OUTPUT.sha256"
fi

cat >&2 <<EOF

Done. Write the image to an SD card with:
  sudo dd if=$(basename -- "${OUTPUT:-$DEVICE}") of=/dev/sdX bs=4M status=progress conv=fsync

Then:
  1. inject hekate via RCM (${HEKATE_RELEASE_URL}),
  2. choose "More configs..." -> "OmarchySwitch (Erista)".

If the screen stays black, read docs/06-known-limitations.md before changing
anything: a wrong kernel/module pair produces exactly that symptom.
EOF
osw_ok "build-image finished"
