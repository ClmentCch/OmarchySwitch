#!/usr/bin/env bash
#
# integrate-omarchy.sh — install the Omarchy 4.5.0 environment into an
# OmarchySwitch root filesystem and apply the Switch adaptations.
#
# Omarchy for aarch64 is published as pacman packages at
#   https://pkgs.omarchy.org/stable/aarch64/   (verified reachable 2026-11-10)
# so integration is a normal pacman repository, not an ISO copy. The ISO is
# explicitly NOT used: it ships its own boot loader, kernel and partitioning.
#
# What this script does:
#   1. adds the [omarchy] repository (aarch64) to the rootfs pacman config,
#   2. refuses to install Omarchy's kernel (linux-omarchy*), which does not
#      support Tegra X1 and would replace the Switchroot kernel,
#   3. installs the packages listed in build/manifests/omarchy-packages.txt,
#   4. applies omarchy/configs/ into the default user's home,
#   5. verifies that no kernel package was replaced.
#
# Usage:
#   sudo ./scripts/integrate-omarchy.sh --rootfs build/output/rootfs [options]
#
# Options:
#   --rootfs DIR        Prepared rootfs (mandatory).
#   --channel CHANNEL   stable (default) or edge.
#   --user NAME         Target user for configurations (default: switch).
#   --configs-only      Skip package installation, only apply configurations.
#   --no-configs        Skip configuration overlay.
#   --dry-run           Print actions without changing anything.
#   --yes               Non-interactive confirmation.
#   -h, --help          This help.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ROOTFS=""
CHANNEL=""
TARGET_USER="${OSW_DEFAULT_USER:-switch}"
CONFIGS_ONLY=0
DO_CONFIGS=1
DRY_RUN=0

usage() { sed -n '2,29p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --rootfs) ROOTFS="${2:-}"; [[ -n "$ROOTFS" ]] || osw_die "--rootfs needs a directory"; shift ;;
    --channel) CHANNEL="${2:-}"; [[ -n "$CHANNEL" ]] || osw_die "--channel needs a value"; shift ;;
    --user) TARGET_USER="${2:-}"; [[ -n "$TARGET_USER" ]] || osw_die "--user needs a value"; shift ;;
    --configs-only) CONFIGS_ONLY=1 ;;
    --no-configs) DO_CONFIGS=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_root
[[ -n "$ROOTFS" ]] || osw_die "--rootfs is required"
ROOTFS="$(realpath -m -- "$ROOTFS")"
osw_require_dir "$ROOTFS"
osw_require_aarch64_tree "$ROOTFS"

CHANNEL="${CHANNEL:-$OMARCHY_PACKAGE_CHANNEL}"
case "$CHANNEL" in
  stable) REPO_URL="$OMARCHY_PKG_REPO_STABLE" ;;
  edge)   REPO_URL="$OMARCHY_PKG_REPO_EDGE" ;;
  *) osw_die "unknown channel '$CHANNEL' (expected stable or edge)" ;;
esac

PACKAGE_MANIFEST="$OSW_ROOT/build/manifests/omarchy-packages.txt"
PACMAN_CONF="$ROOTFS/etc/pacman.conf"
CONFIG_SCRIPT="$OSW_ROOT/omarchy/scripts/apply-configs.sh"
HOME_DIR="$ROOTFS/home/$TARGET_USER"

osw_start_log "integrate-omarchy"

osw_step "Preconditions"
osw_require_file "$PACMAN_CONF"
osw_require_file "$PACKAGE_MANIFEST"
[[ "$OMARCHY_INSTALL_KERNEL" == "0" ]] || osw_die "OMARCHY_INSTALL_KERNEL must stay 0: linux-omarchy does not support Tegra X1"
if [[ ! -d "$HOME_DIR" ]]; then
  osw_die "home directory for '$TARGET_USER' not found: $HOME_DIR
Create the user in build-rootfs.sh or pass --user with an existing account."
fi

if chroot "$ROOTFS" /usr/bin/pacman -Q linux-omarchy >/dev/null 2>&1; then
  osw_die "linux-omarchy is already installed in this rootfs: remove it before continuing.
The Switch must boot the Switchroot L4T kernel, not Omarchy's ARM kernel."
fi

osw_step "Omarchy repository ($CHANNEL)"
MIRROR_FILE="$ROOTFS/etc/pacman.d/omarchy-mirrorlist"
begin_marker="# >>> omarchyswitch: omarchy repository >>>"
end_marker="# <<< omarchyswitch: omarchy repository <<<"

if (( DRY_RUN )); then
  osw_info "dry run: would write $MIRROR_FILE and add [omarchy] to pacman.conf"
else
  osw_ensure_dir "$(dirname -- "$MIRROR_FILE")"
  printf 'Server = %s\n' "$REPO_URL" > "$MIRROR_FILE"
  python3 - "$PACMAN_CONF" "$begin_marker" "$end_marker" <<'PY'
import sys, pathlib
path = pathlib.Path(sys.argv[1])
begin, end = sys.argv[2], sys.argv[3]
text = path.read_text()
if begin in text:
    start = text.index(begin)
    stop = text.index(end) + len(end)
    text = text[:start] + text[stop:]
text = text.rstrip("\n") + "\n\n" + begin + "\n"
text += "[omarchy]\nInclude = /etc/pacman.d/omarchy-mirrorlist\n"
text += end + "\n"
path.write_text(text)
PY
  osw_ok "[omarchy] -> $REPO_URL"
fi

if (( CONFIGS_ONLY )); then
  osw_warn "--configs-only: skipping pacman installation"
else
  osw_step "Installing Omarchy packages"
  mapfile -t OMARCHY_PKGS < <(grep -vE '^\s*(#|$)' "$PACKAGE_MANIFEST" | awk '{print $1}')
  (( ${#OMARCHY_PKGS[@]} > 0 )) || osw_die "no packages in $PACKAGE_MANIFEST"

  # Hard guard: a dependency must never drag Omarchy's kernel in.
  for pkg in "${OMARCHY_PKGS[@]}"; do
    case "$pkg" in
      linux-omarchy*|*linux-omarchy*) osw_die "refusing to install $pkg: incompatible with Tegra X1" ;;
    esac
  done

  osw_info "${#OMARCHY_PKGS[@]} package(s): ${OMARCHY_PKGS[*]}"
  if (( DRY_RUN )); then
    osw_info "dry run: would run pacman -Sy and install the packages above"
  else
    osw_run_logged "pacman -Sy" chroot "$ROOTFS" /usr/bin/pacman -Sy --noconfirm
    osw_run_logged "pacman -S omarchy packages" \
      chroot "$ROOTFS" /usr/bin/pacman -S --noconfirm --needed "${OMARCHY_PKGS[@]}"

    if chroot "$ROOTFS" /usr/bin/pacman -Q linux-omarchy >/dev/null 2>&1; then
      osw_die "linux-omarchy was installed as a dependency. Aborting: the Switch would boot the wrong kernel.
Remove it and re-check build/manifests/omarchy-packages.txt."
    fi
    osw_ok "Omarchy packages installed; Switchroot kernel untouched"
  fi
fi

if (( DO_CONFIGS )); then
  osw_step "Applying OmarchySwitch configurations"
  if [[ ! -x "$CONFIG_SCRIPT" ]]; then
    osw_die "missing or non-executable: $CONFIG_SCRIPT"
  fi
  args=(--home "$HOME_DIR" --user "$TARGET_USER")
  if (( DRY_RUN )); then args+=(--dry-run); fi
  "$CONFIG_SCRIPT" "${args[@]}"
  osw_ok "configurations applied to $HOME_DIR"
fi

osw_step "Verification"
if (( ! DRY_RUN && ! CONFIGS_ONLY )); then
  missing=0
  for binary in usr/bin/omarchy usr/bin/hyprland usr/bin/waybar usr/bin/walker; do
    if [[ -x "$ROOTFS/$binary" ]]; then
      osw_ok "$binary present"
    else
      osw_warn "$binary not found (package layout may differ; check upstream)"
      missing=$((missing + 1))
    fi
  done
  if (( missing > 0 )); then
    osw_warn "$missing expected binary/binaries missing: verify manually before writing an image"
  fi
fi

if (( DRY_RUN )); then
  osw_ok "dry run finished"
  exit 0
fi

cat >&2 <<EOF

Omarchy integrated into $ROOTFS.

Remember: no display server has been tested on Switch hardware in this
version. The Hyprland configuration assumes a 720x1280 panel rotated to
landscape; see desktop/hyprland/README.md.

Next:
  sudo ./scripts/install-desktop.sh --rootfs "$ROOTFS"
EOF
osw_ok "integrate-omarchy finished"
