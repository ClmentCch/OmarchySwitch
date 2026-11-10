#!/usr/bin/env bash
#
# restore-bootfiles.sh — restore the OmarchySwitch hekate configuration on a
# mounted FAT boot partition, keeping a timestamped backup of existing files.
#
# It never touches the root filesystem, the Switchroot binaries or Horizon OS
# entries other than the files it installs.
#
# Usage:
#   ./recovery/restore/restore-bootfiles.sh --target PATH [--dry-run]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

TARGET=""
DRY_RUN=0

usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --target) TARGET="${2:-}"; [[ -n "$TARGET" ]] || osw_die "--target needs a path"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
[[ -n "$TARGET" ]] || osw_die "--target is required (mounted FAT partition)"
TARGET="$(realpath -m -- "$TARGET")"
osw_require_dir "$TARGET"
[[ -d "$TARGET/bootloader" ]] || osw_die "$TARGET has no bootloader/ directory: wrong partition?"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

backup_and_install() {
  local src="$1" rel="$2"
  local dst="$TARGET/$rel"
  if (( DRY_RUN )); then
    osw_info "dry run: $rel"
    return 0
  fi
  if [[ -f "$dst" ]]; then
    cp -a -- "$dst" "$dst.bak-$STAMP"
    osw_info "backup: $rel.bak-$STAMP"
  fi
  install -Dm644 "$src" "$dst"
  osw_ok "$rel"
}

osw_step "Restoring configuration"
backup_and_install "$OSW_ROOT/bootloader/hekate_ipl.ini" "bootloader/hekate_ipl.ini"
for ini in "$OSW_ROOT"/bootloader/configs/*.ini; do
  [[ -f "$ini" ]] || continue
  backup_and_install "$ini" "bootloader/ini/$(basename -- "$ini")"
done

if (( DRY_RUN )); then
  osw_ok "dry run finished"
  exit 0
fi

osw_step "Syntax check"
# Same rules as scripts/validate-architecture.sh: sections, key=value, no
# stray text. Keep this check local so recovery works without the repo scripts.
broken=0
for ini in "$TARGET/bootloader/hekate_ipl.ini" "$TARGET"/bootloader/ini/*.ini; do
  [[ -f "$ini" ]] || continue
  if ! python3 - "$ini" <<'PY'
import sys
path = sys.argv[1]
section = None
for lineno, raw in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("[") and line.endswith("]"):
        section = line[1:-1]
        continue
    if section is None:
        sys.exit(f"{path}:{lineno}: key outside a section")
    if "=" not in line:
        sys.exit(f"{path}:{lineno}: not key=value")
PY
  then
    osw_error "syntax problem in $ini"
    broken=$((broken + 1))
  else
    osw_ok "$(basename -- "$ini")"
  fi
done
(( broken == 0 )) || osw_die "$broken configuration file(s) are invalid"

osw_step "Boot payload check"
missing=0
for rel in "bootloader/sys/nyx.bin" "bootloader/sys/res.pak"; do
  if [[ -f "$TARGET/$rel" ]]; then osw_ok "$rel"; else osw_warn "missing $rel"; missing=$((missing + 1)); fi
done
for rel in uImage initramfs nx-plat.dtimg boot.scr bl31.bin bl33.bin; do
  if [[ -f "$TARGET${SWITCHROOT_BOOT_PREFIX}/$rel" ]]; then
    osw_ok "boot prefix: $rel"
  else
    osw_warn "missing boot prefix file: $rel"
    missing=$((missing + 1))
  fi
done

if (( missing > 0 )); then
  osw_warn "$missing file(s) missing: the entry will fail until they are restored"
  osw_info "Switchroot payloads: switchroot/README.md"
  osw_info "hekate runtime: bootloader/README.md"
  exit 1
fi

osw_ok "boot configuration restored"
