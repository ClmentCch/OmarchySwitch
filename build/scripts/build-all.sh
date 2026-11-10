#!/usr/bin/env bash
#
# build-all.sh — run the whole pipeline in order, stopping at the first
# failure, and produce an image plus a release archive.
#
# This is a convenience wrapper. Each step can still be run on its own; see
# scripts/README.md. Requires root (it is re-executed through sudo) and
# network access for the Arch Linux ARM and Omarchy package downloads.
#
# Usage:
#   ./build/scripts/build-all.sh [--rootfs DIR] [--image FILE] [--size SIZE]
#                                [--skip-rootfs] [--skip-switchroot]
#                                [--skip-omarchy] [--skip-desktop]
#                                [--allow-unpinned-tarball] [--yes]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

ROOTFS=""
IMAGE=""
SIZE=""
SKIP_ROOTFS=0
SKIP_SWITCHROOT=0
SKIP_OMARCHY=0
SKIP_DESKTOP=0
ALLOW_UNPINNED=""

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --rootfs) ROOTFS="${2:-}"; [[ -n "$ROOTFS" ]] || osw_die "--rootfs needs a directory"; shift ;;
    --image) IMAGE="${2:-}"; [[ -n "$IMAGE" ]] || osw_die "--image needs a file"; shift ;;
    --size) SIZE="${2:-}"; [[ -n "$SIZE" ]] || osw_die "--size needs a value"; shift ;;
    --skip-rootfs) SKIP_ROOTFS=1 ;;
    --skip-switchroot) SKIP_SWITCHROOT=1 ;;
    --skip-omarchy) SKIP_OMARCHY=1 ;;
    --skip-desktop) SKIP_DESKTOP=1 ;;
    --allow-unpinned-tarball) ALLOW_UNPINNED="--allow-unpinned-tarball" ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
ROOTFS="${ROOTFS:-$OSW_ROOT/build/output/rootfs}"
IMAGE="${IMAGE:-$OSW_ROOT/build/output/omarchyswitch-${DISTRO_VERSION}.img}"

# Re-execute the whole pipeline as root once, so sudo credentials are not
# asked for at every step.
if [[ "${EUID}" -ne 0 ]]; then
  osw_info "re-executing under sudo (required for rootfs and image steps)"
  exec sudo --preserve-env=OSW_ASSUME_YES,OSW_DEBUG -- "$0" \
    --rootfs "$ROOTFS" --image "$IMAGE" ${SIZE:+--size "$SIZE"} \
    ${SKIP_ROOTFS:+--skip-rootfs} ${SKIP_SWITCHROOT:+--skip-switchroot} \
    ${SKIP_OMARCHY:+--skip-omarchy} ${SKIP_DESKTOP:+--skip-desktop} \
    ${ALLOW_UNPINNED:+$ALLOW_UNPINNED}
fi

START_EPOCH="$(date +%s)"

osw_step "1/7 Validation"
"$OSW_ROOT/scripts/validate-architecture.sh" --quiet

osw_step "2/7 Bootstrap"
# shellcheck disable=SC2086
"$OSW_ROOT/scripts/bootstrap-arch.sh" $ALLOW_UNPINNED

osw_step "3/7 Root filesystem"
if (( SKIP_ROOTFS )); then
  osw_warn "skipped (--skip-rootfs); reusing $ROOTFS"
  osw_require_dir "$ROOTFS"
else
  "$OSW_ROOT/scripts/build-rootfs.sh" --output "$ROOTFS" --yes
fi

osw_step "4/7 Switchroot components"
if (( SKIP_SWITCHROOT )); then
  osw_warn "skipped (--skip-switchroot): the image will not boot without them"
else
  "$OSW_ROOT/scripts/integrate-switchroot.sh" --rootfs "$ROOTFS" --yes
fi

osw_step "5/7 Omarchy"
if (( SKIP_OMARCHY )); then
  osw_warn "skipped (--skip-omarchy)"
else
  "$OSW_ROOT/scripts/integrate-omarchy.sh" --rootfs "$ROOTFS" --yes
fi

osw_step "6/7 Desktop"
if (( SKIP_DESKTOP )); then
  osw_warn "skipped (--skip-desktop)"
else
  "$OSW_ROOT/scripts/install-desktop.sh" --rootfs "$ROOTFS" --yes
fi

osw_step "7/7 Image"
# shellcheck disable=SC2086
"$OSW_ROOT/scripts/build-image.sh" --rootfs "$ROOTFS" --output "$IMAGE" ${SIZE:+--size "$SIZE"} --yes

osw_step "Release archive"
"$OSW_ROOT/scripts/package-release.sh"

ELAPSED=$(( $(date +%s) - START_EPOCH ))
cat >&2 <<EOF

Pipeline finished in $((ELAPSED / 60))m$((ELAPSED % 60))s.
  rootfs: $ROOTFS
  image:  $IMAGE
  archive: $OSW_ROOT/dist/

Not tested on hardware. Read docs/10-testing.md before flashing.
EOF
osw_ok "build-all finished"
