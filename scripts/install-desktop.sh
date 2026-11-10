#!/usr/bin/env bash
#
# install-desktop.sh — install and wire the desktop stack inside an
# OmarchySwitch root filesystem.
#
# Split from integrate-omarchy.sh on purpose:
#   integrate-omarchy.sh  -> Omarchy packages, Omarchy configuration
#   install-desktop.sh    -> graphics/audio/network stack, session plumbing,
#                            fonts, hardware-facing services
#
# This script never installs a kernel and never enables a display manager it
# has not verified. Session start uses uwsm on tty1 with autologin, which is
# the least surprising option on a handheld with no keyboard at boot.
#
# Usage:
#   sudo ./scripts/install-desktop.sh --rootfs build/output/rootfs [options]
#
# Options:
#   --rootfs DIR        Prepared rootfs (mandatory).
#   --user NAME         Autologin user (default: switch).
#   --no-autologin      Do not configure tty1 autologin.
#   --skip-packages     Do not install packages, only write configuration.
#   --dry-run           Print actions without changing anything.
#   --yes               Non-interactive confirmation.
#   -h, --help          This help.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ROOTFS=""
TARGET_USER="${OSW_DEFAULT_USER:-switch}"
AUTOLOGIN=1
SKIP_PACKAGES=0
DRY_RUN=0

usage() { sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --rootfs) ROOTFS="${2:-}"; [[ -n "$ROOTFS" ]] || osw_die "--rootfs needs a directory"; shift ;;
    --user) TARGET_USER="${2:-}"; [[ -n "$TARGET_USER" ]] || osw_die "--user needs a value"; shift ;;
    --no-autologin) AUTOLOGIN=0 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
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

DESKTOP_PACKAGES="$OSW_ROOT/build/manifests/desktop-packages.txt"
HOME_DIR="$ROOTFS/home/$TARGET_USER"

osw_start_log "install-desktop"

osw_require_file "$DESKTOP_PACKAGES"
osw_require_dir "$HOME_DIR"

osw_step "Desktop packages"
if (( SKIP_PACKAGES )); then
  osw_warn "--skip-packages: not installing packages"
else
  mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$DESKTOP_PACKAGES" | awk '{print $1}')
  (( ${#PKGS[@]} > 0 )) || osw_die "no packages in $DESKTOP_PACKAGES"
  osw_info "${#PKGS[@]} package(s)"
  if (( DRY_RUN )); then
    osw_info "dry run: would install: ${PKGS[*]}"
  else
    osw_run_logged "pacman -S desktop packages" \
      chroot "$ROOTFS" /usr/bin/pacman -S --noconfirm --needed "${PKGS[@]}"
    osw_ok "desktop packages installed"
  fi
fi

osw_step "Hardware-facing services"
if (( DRY_RUN )); then
  osw_info "dry run: would enable NetworkManager, bluetooth, seatd"
else
  for unit in NetworkManager.service bluetooth.service seatd.service; do
    if [[ -f "$ROOTFS/usr/lib/systemd/system/$unit" ]]; then
      osw_ensure_dir "$ROOTFS/etc/systemd/system/multi-user.target.wants"
      ln -sf "/usr/lib/systemd/system/$unit" \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/$unit"
      osw_ok "enabled $unit"
    else
      osw_warn "$unit not present in the rootfs (package missing?)"
    fi
  done
  # Sound: PipeWire in user session, WirePlumber as session manager.
  chroot "$ROOTFS" /usr/bin/systemctl --no-reload enable --global \
    pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 \
    && osw_ok "enabled user audio units (pipewire, wireplumber)" \
    || osw_warn "could not enable user audio units (install pipewire/wireplumber first)"
fi

osw_step "Session"
if (( DRY_RUN )); then
  osw_info "dry run: would configure uwsm autologin on tty1"
else
  # uwsm needs XDG_SESSION_TYPE / XDG_CURRENT_DESKTOP in the environment.
  install -Dm644 "$OSW_ROOT/omarchy/configs/environment.d/10-omarchyswitch.conf" \
    "$ROOTFS/etc/environment.d/10-omarchyswitch.conf"
  osw_ok "/etc/environment.d/10-omarchyswitch.conf"

  if (( AUTOLOGIN )); then
    unit_dir="$ROOTFS/etc/systemd/system/getty@tty1.service.d"
    osw_ensure_dir "$unit_dir"
    cat > "$unit_dir/autologin.conf" <<EOF
# OmarchySwitch: start the graphical session on tty1 without a login prompt.
# The account has a locked password until the first boot sets one; physical
# access to the console is the trust boundary, exactly like a handheld OS.
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOF
    osw_ok "tty1 autologin for '$TARGET_USER'"

    profile_file="$HOME_DIR/.bash_profile"
    marker_begin="# >>> omarchyswitch: uwsm session >>>"
    marker_end="# <<< omarchyswitch: uwsm session <<<"
    if [[ -f "$profile_file" ]] && grep -qF "$marker_begin" "$profile_file"; then
      osw_info "uwsm block already present in .bash_profile"
    else
      {
        printf '\n%s\n' "$marker_begin"
        printf '%s\n' '# Start Hyprland through uwsm on tty1.'
        printf '%s\n' 'if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then'
        printf '%s\n' '  exec uwsm start -S -D hyprland-uwsm.desktop'
        printf '%s\n' 'fi'
        printf '%s\n' "$marker_end"
      } >> "$profile_file"
      chown --reference="$HOME_DIR" "$profile_file" 2>/dev/null || true
      osw_ok "uwsm session appended to .bash_profile"
    fi
  else
    osw_warn "--no-autologin: the user must start the session manually (uwsm start -S)"
  fi
fi

osw_step "Default target"
if (( ! DRY_RUN )); then
  ln -sf /usr/lib/systemd/system/graphical.target "$ROOTFS/etc/systemd/system/default.target"
  osw_ok "default.target -> graphical.target"
fi

osw_step "Fonts and themes"
if (( DRY_RUN )); then
  osw_info "dry run: would install fonts from desktop/fonts/packages.txt"
else
  FONT_LIST="$OSW_ROOT/desktop/fonts/packages.txt"
  if [[ -f "$FONT_LIST" ]]; then
    mapfile -t FONTS < <(grep -vE '^\s*(#|$)' "$FONT_LIST" | awk '{print $1}')
    if (( ${#FONTS[@]} > 0 )); then
      osw_run_logged "installing fonts" \
        chroot "$ROOTFS" /usr/bin/pacman -S --noconfirm --needed "${FONTS[@]}"
      osw_ok "${#FONTS[@]} font package(s) installed"
    fi
  fi
  if [[ -x "$OSW_ROOT/omarchy/scripts/apply-configs.sh" ]]; then
    "$OSW_ROOT/omarchy/scripts/apply-configs.sh" --home "$HOME_DIR" --user "$TARGET_USER" --desktop
    osw_ok "desktop configuration overrides applied"
  fi
fi

if (( DRY_RUN )); then
  osw_ok "dry run finished"
  exit 0
fi

cat >&2 <<EOF

Desktop stack installed.

Not verified: whether Hyprland renders on the Switch GPU (GM20B via the L4T
BSP), whether touch input maps correctly, and whether the session survives a
suspend/resume cycle. See docs/05-status-matrix.md before claiming support.

Next:
  sudo ./scripts/build-image.sh --rootfs "$ROOTFS" --output build/output/omarchyswitch.img
EOF
osw_ok "install-desktop finished"
