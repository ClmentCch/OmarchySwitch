#!/usr/bin/env bash
#
# collect.sh — collect the boot state of an OmarchySwitch card into a tarball.
#
# Reads only. Never writes to the card. Never collects personal data:
# home directories, credentials, Wi-Fi secrets and pairing dumps are excluded
# by construction (explicit allowlist, not a denylist).
#
# Usage:
#   ./recovery/diagnostics/collect.sh --sd PATH [--output DIR]
#   sudo ./recovery/diagnostics/collect.sh --image FILE [--output DIR]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

SD=""
IMAGE=""
OUTPUT_DIR=""

usage() { sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --sd) SD="${2:-}"; [[ -n "$SD" ]] || osw_die "--sd needs a path"; shift ;;
    --image) IMAGE="${2:-}"; [[ -n "$IMAGE" ]] || osw_die "--image needs a file"; shift ;;
    --output) OUTPUT_DIR="${2:-}"; [[ -n "$OUTPUT_DIR" ]] || osw_die "--output needs a directory"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_cmds tar sha256sum findmnt

[[ -n "$SD" || -n "$IMAGE" ]] || osw_die "one of --sd or --image is required"
[[ -z "$SD" || -z "$IMAGE" ]] || osw_die "use --sd or --image, not both"
OUTPUT_DIR="${OUTPUT_DIR:-$OSW_ROOT/build/output/diagnostics}"
osw_ensure_dir "$OUTPUT_DIR"

MOUNTED_BY_US=0
WORK="$(osw_tmpdir)"
SD="$(realpath -m -- "${SD:-$WORK/mnt}")"
if [[ -n "$IMAGE" ]]; then
  osw_require_root
  osw_require_file "$IMAGE"
  osw_require_cmds mount umount losetup
  osw_info "mounting $IMAGE read-only"
  mkdir -p "$SD"
  mount -o loop,ro "$IMAGE" "$SD"
  MOUNTED_BY_US=1
fi

cleanup_collect() {
  if (( MOUNTED_BY_US )); then umount "$SD" 2>/dev/null || true; fi
}
trap 'cleanup_collect; osw_cleanup' EXIT

osw_require_dir "$SD"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
STAGE="$WORK/omarchyswitch-diagnostics"
osw_ensure_dir "$STAGE"

osw_step "Collecting card state"
{
  printf 'collected_at=%s\n' "$STAMP"
  printf 'source=%s\n' "${IMAGE:-$SD}"
  printf 'distro_version=%s\n' "$DISTRO_VERSION"
  printf 'kernel_reference=%s\n' "$L4T_KERNEL_VERSION"
  printf 'host_arch=%s\n' "$(osw_host_arch)"
} > "$STAGE/summary.txt"

# Boot tree ---------------------------------------------------------------
if [[ -d "$SD/bootloader" ]]; then
  osw_ok "bootloader/ present"
  mkdir -p "$STAGE/bootloader"
  find "$SD/bootloader" -maxdepth 2 -type f \( -name '*.ini' -o -name '*.txt' \) -print0 2>/dev/null |
    while IFS= read -r -d '' f; do
      rel="${f#"$SD"/}"
      mkdir -p "$STAGE/$(dirname -- "$rel")"
      cp -- "$f" "$STAGE/$rel"
    done
  ( cd "$SD" && find bootloader -type f -printf '%p %s\n' 2>/dev/null ) > "$STAGE/bootloader-files.txt"
else
  osw_warn "no bootloader/ directory (is this the FAT partition?)"
  printf 'bootloader/ missing\n' > "$STAGE/bootloader-files.txt"
fi

if [[ -d "$SD$SWITCHROOT_BOOT_PREFIX" ]]; then
  ( cd "$SD" && find "${SWITCHROOT_BOOT_PREFIX#/}" -maxdepth 1 -type f -printf '%p %s\n' 2>/dev/null ) > "$STAGE/bootprefix-files.txt"
  while IFS= read -r -d '' f; do
    sha256sum "$f" | sed "s#$SD/##"
  done < <(find "$SD$SWITCHROOT_BOOT_PREFIX" -maxdepth 1 -type f -print0 2>/dev/null) \
    > "$STAGE/bootprefix-sha256.txt"
  osw_ok "boot prefix hashed"
else
  osw_warn "no $SWITCHROOT_BOOT_PREFIX directory"
fi

# Root filesystem (allowlist only) ---------------------------------------
ROOT_ITEMS=(
  etc/fstab
  etc/hostname
  etc/os-release
  etc/switchroot_version.conf
  etc/omarchyswitch
  usr/lib/modules
  var/log/omarchyswitch-firstboot.log
)
for rel in "${ROOT_ITEMS[@]}"; do
  src="$SD/$rel"
  [[ -e "$src" ]] || continue
  mkdir -p "$STAGE/rootfs/$(dirname -- "$rel")"
  if [[ -d "$src" ]]; then
    if [[ "$rel" == "usr/lib/modules" ]]; then
      # Only the version directories, not the modules themselves.
      find "$src" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' > "$STAGE/rootfs/$rel/versions.txt"
    else
      cp -a -- "$src" "$STAGE/rootfs/$rel" 2>/dev/null || true
    fi
  else
    cp -- "$src" "$STAGE/rootfs/$rel"
  fi
done

# Journals, if present ----------------------------------------------------
if [[ -d "$SD/var/log/journal" ]]; then
  mkdir -p "$STAGE/rootfs/var/log"
  tar -C "$SD/var/log" -cf - journal 2>/dev/null | tar -C "$STAGE/rootfs/var/log" -xf - 2>/dev/null || true
  osw_ok "journal collected"
fi

# Partitioning ------------------------------------------------------------
{
  if [[ -n "$IMAGE" ]]; then
    echo "image: $IMAGE"
    parted -s "$IMAGE" print 2>/dev/null || true
  else
    echo "path: $SD"
    findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS --target "$SD" 2>/dev/null || true
  fi
} > "$STAGE/partition.txt" 2>&1

# Absolute safety net: nothing from a home directory may be in the archive.
if find "$STAGE" -path '*/home/*' -print -quit 2>/dev/null | grep -q .; then
  osw_die "internal error: home content ended up in the archive"
fi

osw_step "Packing"
ARCHIVE="$OUTPUT_DIR/omarchyswitch-diagnostics-$STAMP.tar.gz"
tar -C "$WORK" -czf "$ARCHIVE" "$(basename -- "$STAGE")"
osw_ok "$ARCHIVE ($(du -h "$ARCHIVE" | awk '{print $1}'))"

osw_step "Contents"
tar -tzf "$ARCHIVE" | sed 's/^/  /' >&2

cat >&2 <<EOF

Review the list above before sharing: it should contain no document, no
credential and no Wi-Fi configuration.
EOF
osw_ok "collect finished"
