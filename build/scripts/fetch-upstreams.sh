#!/usr/bin/env bash
#
# fetch-upstreams.sh — fetch the pinned upstream sources (Omarchy, hekate)
# into build/src/, without touching the system.
#
# Omarchy and hekate are both small repositories and are useful locally:
#   build/src/omarchy  -> exact v4.5.0 tree, for configuration reference
#   build/src/hekate   -> bootloader sources and the official bootloader/ bundle
#
# The Arch Linux ARM tarball is handled by scripts/bootstrap-arch.sh.
#
# Usage:
#   ./build/scripts/fetch-upstreams.sh [--check] [--force] [--all]
#
# Options:
#   --check   Only verify that the pinned tags exist upstream (network).
#   --force   Re-clone even when a checkout is already present.
#   --all     Also fetch the Switchroot kernel/bootstack sources (large).
#   -h, --help

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

CHECK_ONLY=0
FORCE=0
ALL=0

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --force) FORCE=1 ;;
    --all) ALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_cmds git

SRC="$OSW_ROOT/build/src"
osw_ensure_dir "$SRC"

clone_pinned() {
  local name="$1" url="$2" ref="$3" dest="$4"
  osw_step "$name ($ref)"
  if (( CHECK_ONLY )); then
    if git ls-remote --exit-code --tags "$url" "$ref" >/dev/null 2>&1; then
      osw_ok "tag $ref exists upstream"
    else
      osw_die "tag $ref not found in $url"
    fi
    return 0
  fi
  if [[ -d "$dest/.git" && "$FORCE" -eq 1 ]]; then
    rm -rf -- "$dest"
  fi
  if [[ -d "$dest/.git" ]]; then
    osw_info "already present: $dest (use --force to re-clone)"
  else
    git clone --quiet --branch "$ref" --depth 1 "$url" "$dest" || osw_die "clone failed: $url"
  fi
  local head describe
  head="$(git -C "$dest" rev-parse HEAD)"
  describe="$(git -C "$dest" describe --tags --always 2>/dev/null || echo "$ref")"
  osw_ok "$name: $describe ($head)"
  printf '%s\t%s\t%s\n' "$name" "$describe" "$head" >> "$SRC/upstreams.lock"
}

rm -f -- "$SRC/upstreams.lock"
clone_pinned "omarchy" "$OMARCHY_REPO" "$OMARCHY_TAG" "$SRC/omarchy"
clone_pinned "hekate" "$HEKATE_REPO" "$HEKATE_VERSION" "$SRC/hekate"

if (( ALL )); then
  clone_pinned "switchroot-kernel" "$SWITCHROOT_KERNEL_REPO" "$SWITCHROOT_KERNEL_REF" "$SRC/l4t-kernel-4.9"
  clone_pinned "switchroot-uboot" "$SWITCHROOT_UBOOT_REPO" "$SWITCHROOT_UBOOT_BRANCH" "$SRC/switch-uboot"
  clone_pinned "switchroot-atf" "$SWITCHROOT_ATF_REPO" "$SWITCHROOT_ATF_BRANCH" "$SRC/switch-atf"
fi

if (( CHECK_ONLY )); then
  osw_ok "upstream references verified"
  exit 0
fi

osw_step "Bootloader bundle"
# hekate releases ship the bootloader/ folder hekate needs at runtime
# (nyx.bin, res.pak, sys/l4t/*). We point at the official release instead of
# rebuilding hekate, which would need devkitARM.
cat >&2 <<EOF
hekate's runtime files (bootloader/sys/nyx.bin, res.pak, sys/l4t/bpmpfw*.bin)
come from the official release, not from a source build:

  ${HEKATE_RELEASE_URL}

Download the release zip, then either:
  * copy its bootloader/ folder to the FAT partition, and let
    bootloader/configs/omarchyswitch-erista.ini add the OmarchySwitch entry, or
  * run ./bootloader/scripts/install-bootfiles.sh --hekate-zip <file> --target <path>

Missing bootloader/sys files make hekate refuse to boot L4T with
"missing lp0 (sleep) lib / missing minerva lib / update bootloader folder!".
EOF

osw_step "Licenses fetched"
for pair in "omarchy:$SRC/omarchy/LICENSE" "hekate:$SRC/hekate/LICENSE"; do
  name="${pair%%:*}"
  path="${pair#*:}"
  if [[ -f "$path" ]]; then
    osw_ok "$name: $(head -n1 "$path")"
  else
    osw_warn "$name: license file not found at ${path#"$OSW_ROOT/"}"
  fi
done

osw_ok "fetch-upstreams finished"
