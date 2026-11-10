#!/usr/bin/env bash
#
# install-bootfiles.sh — install the OmarchySwitch hekate configuration onto a
# mounted FAT boot partition, optionally merging the official hekate release.
#
# Nothing is downloaded. You point at a hekate release zip you already have
# (or an already extracted bootloader/ folder) and at the mounted partition.
#
# What it does:
#   1. checks that the target looks like a boot partition,
#   2. merges hekate's own bootloader/ files (nyx, res.pak, sys/, ...),
#   3. installs hekate_ipl.ini without silently overwriting a different one,
#   4. installs the OmarchySwitch entries into bootloader/ini/,
#   5. reports missing runtime files that make hekate refuse to boot L4T.
#
# Usage:
#   ./bootloader/scripts/install-bootfiles.sh --target /run/media/user/OMARCHYSW \
#       [--hekate-zip FILE | --hekate-dir DIR] [--force]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

TARGET=""
HEKATE_ZIP=""
HEKATE_DIR=""
FORCE=0

usage() { sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --target) TARGET="${2:-}"; [[ -n "$TARGET" ]] || osw_die "--target needs a path"; shift ;;
    --hekate-zip) HEKATE_ZIP="${2:-}"; [[ -n "$HEKATE_ZIP" ]] || osw_die "--hekate-zip needs a file"; shift ;;
    --hekate-dir) HEKATE_DIR="${2:-}"; [[ -n "$HEKATE_DIR" ]] || osw_die "--hekate-dir needs a directory"; shift ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
[[ -n "$TARGET" ]] || osw_die "--target is required (the mounted FAT boot partition)"
TARGET="$(realpath -m -- "$TARGET")"
osw_require_dir "$TARGET"
osw_require_cmds unzip

if [[ "$TARGET" == "/" || "$TARGET" == "/boot" ]]; then
  osw_die "refusing to install into '$TARGET': point at the mounted SD card partition"
fi
if [[ ! -d "$TARGET/bootloader" ]] && ! osw_dir_is_empty "$TARGET"; then
  osw_warn "$TARGET is not empty and has no bootloader/ directory"
  osw_confirm "Continue anyway?"
fi

osw_step "hekate runtime files"
if [[ -n "$HEKATE_ZIP" ]]; then
  osw_require_file "$HEKATE_ZIP"
  if ! unzip -l "$HEKATE_ZIP" | grep -q 'bootloader/'; then
    osw_die "$HEKATE_ZIP does not contain a bootloader/ directory (is this the hekate release zip?)"
  fi
  osw_info "merging $HEKATE_ZIP"
  unzip -o -q "$HEKATE_ZIP" 'bootloader/*' -d "$TARGET"
  osw_ok "hekate release merged into $TARGET/bootloader"
elif [[ -n "$HEKATE_DIR" ]]; then
  osw_require_dir "$HEKATE_DIR"
  if [[ ! -d "$HEKATE_DIR/bootloader" ]]; then
    osw_die "$HEKATE_DIR has no bootloader/ subdirectory"
  fi
  cp -a -- "$HEKATE_DIR/bootloader/." "$TARGET/bootloader/"
  osw_ok "hekate files copied from $HEKATE_DIR"
else
  osw_warn "no --hekate-zip/--hekate-dir given: assuming $TARGET already contains hekate's bootloader/"
fi

osw_step "Main configuration"
main_ini="$TARGET/bootloader/hekate_ipl.ini"
if [[ -f "$main_ini" ]] && ! cmp -s "$OSW_ROOT/bootloader/hekate_ipl.ini" "$main_ini"; then
  if (( FORCE )); then
    osw_warn "overwriting existing hekate_ipl.ini (--force)"
  else
    osw_warn "an existing hekate_ipl.ini differs (probably your Horizon OS entries)"
    if ! osw_confirm "Replace it with the OmarchySwitch version? (a backup is kept as .bak)"; then
      osw_info "keeping the existing file; install only the ini/ entries"
    else
      cp -a -- "$main_ini" "$main_ini.bak"
      install -Dm644 "$OSW_ROOT/bootloader/hekate_ipl.ini" "$main_ini"
      osw_ok "installed hekate_ipl.ini (backup: hekate_ipl.ini.bak)"
    fi
  fi
else
  if (( FORCE )); then
    install -Dm644 "$OSW_ROOT/bootloader/hekate_ipl.ini" "$main_ini"
    osw_ok "installed hekate_ipl.ini"
  elif [[ ! -f "$main_ini" ]]; then
    install -Dm644 "$OSW_ROOT/bootloader/hekate_ipl.ini" "$main_ini"
    osw_ok "installed hekate_ipl.ini"
  else
    osw_ok "hekate_ipl.ini already up to date"
  fi
fi

osw_step "Booter entries"
for ini in "$OSW_ROOT"/bootloader/configs/*.ini; do
  [[ -f "$ini" ]] || continue
  install -Dm644 "$ini" "$TARGET/bootloader/ini/$(basename -- "$ini")"
  osw_ok "bootloader/ini/$(basename -- "$ini")"
done

osw_step "Runtime file check"
missing=0
required=(
  bootloader/sys/nyx.bin
  bootloader/sys/res.pak
  bootloader/sys/libsys_lp0.bso
  bootloader/sys/libsys_minerva.bso
)
for rel in "${required[@]}"; do
  if [[ -f "$TARGET/$rel" ]]; then
    osw_ok "$rel"
  else
    osw_warn "missing: $rel"
    missing=$((missing + 1))
  fi
done
if compgen -G "$TARGET/bootloader/sys/l4t/bpmpfw*" >/dev/null; then
  osw_ok "bootloader/sys/l4t/bpmpfw*"
else
  osw_warn "missing: bootloader/sys/l4t/bpmpfw*.bin"
  missing=$((missing + 1))
fi
if compgen -G "$TARGET/bootloader/sys/l4t/mtc_tbl*" >/dev/null; then
  osw_ok "bootloader/sys/l4t/mtc_tbl*"
else
  osw_warn "missing: bootloader/sys/l4t/mtc_tbl*.bin"
  missing=$((missing + 1))
fi

if (( missing > 0 )); then
  osw_warn "$missing hekate runtime file(s) missing: L4T boot will fail with"
  osw_warn "\"missing lp0 (sleep) lib / missing minerva lib / update bootloader folder!\""
  osw_info "Copy the full bootloader/ folder from the official release: $HEKATE_RELEASE_URL"
  exit 1
fi

osw_step "Bridge files"
prefix_rel="${SWITCHROOT_BOOT_PREFIX#/}"
if [[ -d "$TARGET/$prefix_rel" ]]; then
  osw_ok "boot prefix present: $prefix_rel"
else
  osw_warn "boot prefix absent: $prefix_rel (integrate-switchroot.sh creates it in the staging tree)"
fi

osw_ok "boot files installed in $TARGET"
