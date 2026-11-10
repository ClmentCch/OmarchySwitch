#!/usr/bin/env bash
#
# build-rootfs.sh — build an Arch Linux ARM64 root filesystem for
# OmarchySwitch (Nintendo Switch V1, Erista).
#
# Pipeline:
#   1. extract the pinned Arch Linux ARM aarch64 tarball,
#   2. install the project pacman configuration and mirrorlist,
#   3. initialise the pacman keyring inside the rootfs,
#   4. upgrade the base system and install build/manifests/base-packages.txt,
#   5. configure systemd basics (locale, timezone, hostname, machine-id),
#   6. apply archlinux/rootfs/overlay/,
#   7. create the default user and enable the first-boot unit,
#   8. verify the result is aarch64 and contains no foreign-architecture ELF,
#   9. write /etc/omarchyswitch/build-info.
#
# The Arch Linux ARM tarball already contains systemd. This script does not
# and cannot make systemd compatible with the Switchroot L4T 4.9 kernel; see
# docs/adr/0004-systemd-kernel-compatibility.md.
#
# Usage:
#   sudo ./scripts/build-rootfs.sh --output build/output/rootfs [options]
#
# Options:
#   --output DIR        Target rootfs directory (must be empty or absent).
#   --stage-only        Extract + configure pacman, skip package installation.
#   --no-packages       Same as --stage-only.
#   --keep-cache        Keep pacman's package cache in the rootfs.
#   --yes               Non-interactive confirmation.
#   -h, --help          This help.
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

OUTPUT_DIR=""
STAGE_ONLY=0
KEEP_CACHE=0

usage() {
  sed -n '2,33p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while (( $# )); do
  case "$1" in
    --output) OUTPUT_DIR="${2:-}"; [[ -n "$OUTPUT_DIR" ]] || osw_die "--output needs a directory"; shift ;;
    --stage-only|--no-packages) STAGE_ONLY=1 ;;
    --keep-cache) KEEP_CACHE=1 ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_target_arch
osw_require_root
osw_require_cmds tar curl python3 sha256sum

[[ -n "$OUTPUT_DIR" ]] || osw_die "--output is required (e.g. --output build/output/rootfs)"
OUTPUT_DIR="$(realpath -m -- "$OUTPUT_DIR")"
osw_require_empty_or_absent "$OUTPUT_DIR"

TARBALL="${ALARM_TARBALL_URL##*/}"
CACHE_TARBALL="$OSW_ROOT/build/cache/$TARBALL"
PACMAN_CONF_SRC="$OSW_ROOT/$ALARM_PACMAN_CONF"
MIRRORLIST_SRC="$OSW_ROOT/$ALARM_MIRRORLIST"
OVERLAY_DIR="$OSW_ROOT/archlinux/rootfs/overlay"
BASE_PACKAGES="$OSW_ROOT/build/manifests/base-packages.txt"
DEFAULT_USER="${OSW_DEFAULT_USER:-switch}"

osw_start_log "build-rootfs"

osw_step "Preflight"
osw_require_file "$PACMAN_CONF_SRC"
osw_require_file "$MIRRORLIST_SRC"
osw_require_dir "$OVERLAY_DIR"
osw_require_file "$BASE_PACKAGES"
if ! osw_check_binfmt; then
  osw_die "cannot build an aarch64 rootfs on this host yet (see instructions above)"
fi

osw_step "Root filesystem tarball"
if [[ ! -f "$CACHE_TARBALL" ]]; then
  osw_die "bootstrap tarball missing: $CACHE_TARBALL
Run ./scripts/bootstrap-arch.sh first (it pins/prints the SHA-256)."
fi
observed_sha="$(osw_sha256 "$CACHE_TARBALL")"
if [[ -n "${ALARM_TARBALL_SHA256:-}" && "$observed_sha" != "$ALARM_TARBALL_SHA256" ]]; then
  osw_die "cached tarball does not match ALARM_TARBALL_SHA256 (run bootstrap-arch.sh --force)"
fi
osw_ok "tarball verified: $CACHE_TARBALL"

osw_step "Extracting aarch64 root filesystem"
osw_ensure_dir "$OUTPUT_DIR"
tar -xpf "$CACHE_TARBALL" -C "$OUTPUT_DIR"
osw_require_aarch64_tree "$OUTPUT_DIR"
osw_ok "extracted and verified as aarch64: $OUTPUT_DIR"

osw_step "pacman configuration"
install -Dm644 "$PACMAN_CONF_SRC" "$OUTPUT_DIR/etc/pacman.conf"
install -Dm644 "$MIRRORLIST_SRC" "$OUTPUT_DIR/etc/pacman.d/mirrorlist"
# The Arch Linux ARM rootfs ships a stub mirrorlist; make sure ours wins.
install -Dm644 "$OVERLAY_DIR/etc/resolv.conf" "$OUTPUT_DIR/etc/resolv.conf"
osw_ok "pacman.conf, mirrorlist and resolv.conf installed"

osw_step "pacman keyring"
if ! chroot "$OUTPUT_DIR" /usr/bin/pacman-key --init; then
  osw_die "pacman-key --init failed (is binfmt registered and /proc mounted?)"
fi
if ! chroot "$OUTPUT_DIR" /usr/bin/pacman-key --populate archlinuxarm; then
  osw_die "pacman-key --populate archlinuxarm failed (check the mirrorlist and network)"
fi
osw_ok "keyring initialised"

if (( STAGE_ONLY )); then
  osw_warn "stage-only requested: skipping system upgrade and package installation"
else
  osw_step "Base system upgrade"
  osw_run_logged "pacman -Syu" chroot "$OUTPUT_DIR" /usr/bin/pacman -Syu --noconfirm --needed

  osw_step "Installing base packages"
  mapfile -t BASE_PKGS < <(grep -vE '^\s*(#|$)' "$BASE_PACKAGES")
  (( ${#BASE_PKGS[@]} > 0 )) || osw_die "no packages listed in $BASE_PACKAGES"
  osw_info "${#BASE_PKGS[@]} packages from build/manifests/base-packages.txt"
  osw_run_logged "pacman -S base packages" \
    chroot "$OUTPUT_DIR" /usr/bin/pacman -S --noconfirm --needed "${BASE_PKGS[@]}"
fi

osw_step "Base configuration"
osw_ensure_dir "$OUTPUT_DIR/etc/systemd/system"
osw_ensure_dir "$OUTPUT_DIR/etc/systemd/system/multi-user.target.wants"

# hostname
install -Dm644 "$OSW_ROOT/archlinux/rootfs/overlay/etc/hostname" "$OUTPUT_DIR/etc/hostname"
# os-release (branding)
install -Dm644 "$OSW_ROOT/archlinux/rootfs/overlay/etc/os-release" "$OUTPUT_DIR/etc/os-release"
# switchroot initramfs hand-off marker (required by the L4T initramfs)
install -Dm644 "$OSW_ROOT/archlinux/rootfs/overlay/etc/switchroot_version.conf" \
  "$OUTPUT_DIR/etc/switchroot_version.conf"
# fstab template: partition labels are resolved by label, never by device node
install -Dm644 "$OSW_ROOT/archlinux/rootfs/overlay/etc/fstab.template" "$OUTPUT_DIR/etc/fstab"
sed -i "s/@BOOT_LABEL@/$BOOT_FS_LABEL/g; s/@ROOT_LABEL@/$ROOT_FS_LABEL/g" "$OUTPUT_DIR/etc/fstab"
# first-boot unit
install -Dm755 "$OSW_ROOT/archlinux/rootfs/firstboot/omarchyswitch-firstboot.sh" \
  "$OUTPUT_DIR/usr/local/sbin/omarchyswitch-firstboot"
install -Dm644 "$OSW_ROOT/archlinux/rootfs/overlay/etc/systemd/system/omarchyswitch-firstboot.service" \
  "$OUTPUT_DIR/etc/systemd/system/omarchyswitch-firstboot.service"

if [[ -d "$OVERLAY_DIR" ]]; then
  osw_info "applying archlinux/rootfs/overlay/"
  cp -a -- "$OVERLAY_DIR/." "$OUTPUT_DIR/"
fi

osw_step "System settings"
# Locale: generate en_US.UTF-8 and fr_FR.UTF-8 (the project documentation and
# its primary user are French; both are harmless).
if [[ -f "$OUTPUT_DIR/etc/locale.gen" ]]; then
  sed -i -E 's/^#\s*(en_US\.UTF-8 UTF-8)/\1/; s/^#\s*(fr_FR\.UTF-8 UTF-8)/\1/' "$OUTPUT_DIR/etc/locale.gen"
fi
printf 'LANG=fr_FR.UTF-8\n' > "$OUTPUT_DIR/etc/locale.conf"
ln -sf /usr/share/zoneinfo/Europe/Paris "$OUTPUT_DIR/etc/localtime"
# Arch Linux ARM ships an empty machine-id; systemd requires a real one.
if [[ -f "$OUTPUT_DIR/etc/machine-id" ]] && [[ ! -s "$OUTPUT_DIR/etc/machine-id" ]]; then
  head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$OUTPUT_DIR/etc/machine-id"
  osw_ok "generated /etc/machine-id"
fi
osw_ok "locale, timezone and machine-id configured"

osw_step "Default user"
if [[ ! -e "$OUTPUT_DIR/home/$DEFAULT_USER" ]]; then
  chroot "$OUTPUT_DIR" /usr/bin/useradd -m -G wheel,video,audio,input,render -s /bin/bash "$DEFAULT_USER"
  # Locked account with no password; the first boot sets one. Never ship a
  # known password.
  chroot "$OUTPUT_DIR" /usr/bin/passwd -l "$DEFAULT_USER" >/dev/null 2>&1 || true
  osw_ok "user '$DEFAULT_USER' created (locked password, set it at first boot)"
else
  osw_warn "user '$DEFAULT_USER' already exists; left untouched"
fi

osw_step "Enabling units"
for unit in systemd-timesyncd.service omarchyswitch-firstboot.service; do
  unit_target=""
  if [[ -f "$OUTPUT_DIR/usr/lib/systemd/system/$unit" ]]; then
    unit_target="/usr/lib/systemd/system/$unit"
  elif [[ -f "$OUTPUT_DIR/etc/systemd/system/$unit" ]]; then
    unit_target="/etc/systemd/system/$unit"
  fi
  if [[ -n "$unit_target" ]]; then
    ln -sf "$unit_target" "$OUTPUT_DIR/etc/systemd/system/multi-user.target.wants/$unit"
    osw_ok "enabled $unit -> $unit_target"
  else
    osw_warn "unit not installed, cannot enable: $unit"
  fi
done

osw_step "Cleanup"
if (( KEEP_CACHE )); then
  osw_info "keeping pacman cache in $OUTPUT_DIR/var/cache/pacman/pkg"
else
  rm -rf -- "$OUTPUT_DIR/var/cache/pacman/pkg"/* 2>/dev/null || true
fi
rm -f -- "$OUTPUT_DIR/etc/resolv.conf"
ln -sf /run/systemd/resolve/stub-resolv.conf "$OUTPUT_DIR/etc/resolv.conf" 2>/dev/null || true

osw_step "Verification"
osw_require_aarch64_tree "$OUTPUT_DIR"
osw_assert_no_foreign_elf "$OUTPUT_DIR" 120
[[ -f "$OUTPUT_DIR/etc/switchroot_version.conf" ]] || osw_die "missing /etc/switchroot_version.conf"
[[ -f "$OUTPUT_DIR/etc/fstab" ]] || osw_die "missing /etc/fstab"
if [[ -x "$OUTPUT_DIR/usr/bin/pacman" ]]; then
  pkg_count="$(ls -1 "$OUTPUT_DIR/var/lib/pacman/local" 2>/dev/null | wc -l | tr -d ' ')"
  osw_ok "installed packages: $pkg_count"
fi

osw_step "Build info"
install -Dm644 /dev/null "$OUTPUT_DIR/etc/omarchyswitch/build-info"
{
  printf 'DISTRO_NAME=%s\n' "$DISTRO_NAME"
  printf 'DISTRO_VERSION=%s\n' "$DISTRO_VERSION"
  printf 'TARGET_ARCH=%s\n' "$TARGET_ARCH"
  printf 'TARGET_MODEL=%s\n' "$TARGET_MODEL"
  printf 'BUILT_AT=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'BUILT_ON=%s\n' "$(osw_host_arch)"
  printf 'ALARM_TARBALL_SHA256=%s\n' "$observed_sha"
  printf 'KERNEL_PROVIDER=switchroot\n'
  printf 'KERNEL_COMPAT_NOTE=systemd requires >= %s, Switchroot L4T kernel is %s\n' \
    "${SYSTEMD_MIN_KERNEL:-4.15}" "${L4T_KERNEL_VERSION:-4.9.140}"
} > "$OUTPUT_DIR/etc/omarchyswitch/build-info"
osw_ok "$OUTPUT_DIR/etc/omarchyswitch/build-info"

cat >&2 <<EOF

Root filesystem ready: $OUTPUT_DIR
Size: $(du -sh "$OUTPUT_DIR" | awk '{print $1}')

This rootfs has no kernel, no modules, no firmware and no DTB: those are
Switchroot components and are integrated separately.

Next:
  sudo ./scripts/integrate-switchroot.sh --rootfs "$OUTPUT_DIR"
EOF
osw_ok "build-rootfs finished"
