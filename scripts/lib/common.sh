#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers for every OmarchySwitch script.
#
# Usage:
#   source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib/common.sh"
#   osw_load_config
#
# Running this file directly prints the effective configuration:
#   ./scripts/lib/common.sh --print-config

set -euo pipefail

# --- Paths -----------------------------------------------------------------
_osw_common_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OSW_SCRIPT_DIR="$_osw_common_dir"
OSW_ROOT="$(cd -- "$_osw_common_dir/../.." && pwd -P)"
readonly OSW_SCRIPT_DIR OSW_ROOT

OSW_CONFIG_FILE="$OSW_ROOT/configs/omarchyswitch.conf"
OSW_LOCAL_CONFIG="$OSW_ROOT/configs/local.conf"
OSW_VERSIONS_FILE="$OSW_ROOT/configs/versions.lock"

# --- Output ----------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _osw_c_reset=$'\033[0m'
  _osw_c_bold=$'\033[1m'
  _osw_c_dim=$'\033[2m'
  _osw_c_red=$'\033[31m'
  _osw_c_green=$'\033[32m'
  _osw_c_yellow=$'\033[33m'
  _osw_c_blue=$'\033[34m'
else
  _osw_c_reset='' _osw_c_bold='' _osw_c_dim=''
  _osw_c_red='' _osw_c_green='' _osw_c_yellow='' _osw_c_blue=''
fi

osw_log()   { printf '%s\n' "$*" >&2; }
osw_info()  { printf '%s==>%s %s\n' "$_osw_c_blue" "$_osw_c_reset" "$*" >&2; }
osw_step()  { printf '\n%s==>%s %s%s%s\n' "$_osw_c_blue" "$_osw_c_reset" "$_osw_c_bold" "$*" "$_osw_c_reset" >&2; }
osw_ok()    { printf '%s ok %s %s\n' "$_osw_c_green" "$_osw_c_reset" "$*" >&2; }
osw_warn()  { printf '%swarn%s %s\n' "$_osw_c_yellow" "$_osw_c_reset" "$*" >&2; }
osw_error() { printf '%sfail%s %s\n' "$_osw_c_red" "$_osw_c_reset" "$*" >&2; }

osw_die() {
  osw_error "$*"
  exit 1
}

osw_debug() {
  [[ "${OSW_DEBUG:-0}" == "1" ]] || return 0
  printf '%sdebug%s %s\n' "$_osw_c_dim" "$_osw_c_reset" "$*" >&2
}

# --- Configuration ---------------------------------------------------------
# Loads defaults, then the optional machine-local override, then the pinned
# version lock. Everything is exported so child processes see one truth.
osw_load_config() {
  [[ -f "$OSW_CONFIG_FILE" ]] || osw_die "missing configuration: $OSW_CONFIG_FILE"

  set -a
  # shellcheck source=/dev/null
  source "$OSW_CONFIG_FILE"
  if [[ -f "$OSW_LOCAL_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$OSW_LOCAL_CONFIG"
  fi
  if [[ -f "$OSW_VERSIONS_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$OSW_VERSIONS_FILE"
  fi
  set +a
}

osw_print_config() {
  osw_load_config
  osw_info "repository: $OSW_ROOT"
  local var
  for var in $(compgen -v | grep -E '^(DISTRO|TARGET|ENFORCE|ALARM|OMARCHY|HEKATE|SWITCHROOT|BOOT_|ROOT_|IMAGE_|DESKTOP_|BUILD_|SAFETY_|SYSTEMD_|L4T_|HYPRLAND|WAYBAR|UWSM)' | sort -u); do
    printf '%-28s = %s\n' "$var" "${!var}"
  done
}

# --- Preconditions ---------------------------------------------------------
osw_have() { command -v "$1" >/dev/null 2>&1; }

osw_require_cmds() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    osw_have "$cmd" || missing+=("$cmd")
  done
  if (( ${#missing[@]} > 0 )); then
    osw_die "missing required command(s): ${missing[*]}"
  fi
}

osw_require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    osw_die "this step needs root (it writes into a root filesystem or a disk image). Re-run with sudo."
  fi
}

osw_require_file() {
  local path="$1"
  [[ -f "$path" ]] || osw_die "required file not found: $path"
}

osw_require_dir() {
  local path="$1"
  [[ -d "$path" ]] || osw_die "required directory not found: $path"
}

# Confirmation gate for destructive or irreversible operations.
# OSW_ASSUME_YES=1 (set by --yes) bypasses the prompt; a non-interactive
# shell without it fails rather than guessing.
osw_confirm() {
  local prompt="$1"
  if [[ "${OSW_ASSUME_YES:-0}" == "1" ]]; then
    osw_debug "auto-confirmed: $prompt"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    osw_die "refusing without confirmation (non-interactive shell): $prompt — pass --yes if you are sure"
  fi
  local reply
  printf '%s [y/N] ' "$prompt" >&2
  read -r reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) osw_die "aborted by user" ;;
  esac
}

# --- Architecture guards ---------------------------------------------------
# The entire project targets aarch64. These helpers make violations loud.
osw_require_target_arch() {
  [[ "${TARGET_ARCH:-}" == "aarch64" ]] || osw_die "TARGET_ARCH is '${TARGET_ARCH:-unset}', expected 'aarch64'"
}

osw_host_arch() { uname -m; }

osw_require_aarch64_tree() {
  local root="$1"
  local probe
  for probe in usr/bin/bash bin/bash usr/bin/pacman; do
    if [[ -e "$root/$probe" ]]; then
      if ! osw_is_aarch64_elf "$root/$probe"; then
        osw_die "rootfs is not aarch64: $probe is $(osw_elf_machine "$root/$probe")"
      fi
      return 0
    fi
  done
  osw_die "cannot verify aarch64 rootfs at $root (no shell or pacman binary found)"
}

osw_is_aarch64_elf() {
  local file_path="$1"
  [[ -f "$file_path" ]] || return 1
  # Read the ELF header directly: works without `file`, and on any host.
  local header
  header="$(od -An -tx1 -N20 "$file_path" 2>/dev/null | tr -d ' \n')" || return 1
  # 7f 45 4c 46 ... e_machine at offset 0x12, little-endian => b7 00 (183)
  [[ "$header" == 7f454c46* ]] || return 1
  [[ "${header:36:4}" == "b700" ]]
}

osw_elf_machine() {
  local file_path="$1"
  local header
  header="$(od -An -tx1 -N20 "$file_path" 2>/dev/null | tr -d ' \n')" || { echo unknown; return 0; }
  if [[ "$header" != 7f454c46* ]]; then
    echo "not-an-elf"
    return 0
  fi
  case "${header:36:4}" in
    b700) echo aarch64 ;;
    3e00) echo x86_64 ;;
    0300) echo i386 ;;
    *) echo "elf-machine-${header:36:4}" ;;
  esac
}

# Fails when a tree contains foreign-architecture ELF binaries (checks the
# first ~200 executables, which is enough to catch a wrong tarball).
osw_assert_no_foreign_elf() {
  local root="$1"
  local limit="${2:-200}"
  local count=0
  local bad=0
  local path machine
  while IFS= read -r -d '' path; do
    count=$((count + 1))
    if (( count > limit )); then break; fi
    machine="$(osw_elf_machine "$path")"
    case "$machine" in
      aarch64|not-an-elf) ;;
      *) bad=$((bad + 1)); osw_error "foreign binary ($machine): ${path#"$root"}";;
    esac
  done < <(find "$root" -type f -perm -u+x -print0 2>/dev/null)
  (( bad == 0 )) || osw_die "$bad foreign-architecture binaries found under $root"
}

# --- Filesystem helpers ----------------------------------------------------
osw_sha256() {
  local target="$1"
  if [[ -d "$target" ]]; then
    # Stable tree digest: hash of the sorted per-file hashes.
    ( cd "$target" && find . -type f -print0 | sort -z | xargs -0 -r sha256sum ) | sha256sum | awk '{print $1}'
  else
    sha256sum "$target" | awk '{print $1}'
  fi
}

osw_file_bytes() {
  local target="$1"
  if stat -c '%s' "$target" >/dev/null 2>&1; then
    stat -c '%s' "$target"
  else
    wc -c <"$target" | tr -d ' '
  fi
}

osw_dir_is_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  [[ -z "$(ls -A -- "$dir" 2>/dev/null)" ]]
}

osw_require_empty_or_absent() {
  local dir="$1"
  if [[ -d "$dir" ]] && ! osw_dir_is_empty "$dir"; then
    osw_die "refusing to write into non-empty directory: $dir"
  fi
}

# Requires at least $2 MiB free on the filesystem holding $1.
osw_require_free_space() {
  local path="$1"
  local need_mb="$2"
  local avail_mb
  avail_mb="$(df -Pm -- "$path" 2>/dev/null | awk 'NR==2 {print $4}')" || true
  if [[ -z "$avail_mb" ]]; then
    osw_warn "cannot determine free space for $path"
    return 0
  fi
  if (( avail_mb < need_mb )); then
    osw_die "not enough free space on $path: ${avail_mb} MiB available, ${need_mb} MiB required"
  fi
}

osw_ensure_dir() { mkdir -p -- "$1"; }

osw_copy() {
  local src="$1" dst="$2"
  mkdir -p -- "$(dirname -- "$dst")"
  cp -a -- "$src" "$dst"
}

# --- Build-tree helpers ----------------------------------------------------
# Staging tree for the FAT partition (what hekate reads).
osw_boot_tree() { printf '%s' "${OSW_BOOT_TREE:-$OSW_ROOT/build/output/boot}"; }

osw_log_dir() {
  local dir="${BUILD_LOG_DIR:-build/output/logs}"
  [[ "$dir" = /* ]] || dir="$OSW_ROOT/$dir"
  mkdir -p -- "$dir"
  printf '%s' "$dir"
}

osw_start_log() {
  local name="$1"
  OSW_LOG_FILE="$(osw_log_dir)/${name}-$(date -u +%Y%m%dT%H%M%SZ).log"
  export OSW_LOG_FILE
  osw_debug "log: $OSW_LOG_FILE"
}

# Run a command, teeing its output into the build log.
osw_run_logged() {
  local desc="$1"
  shift
  osw_info "$desc"
  if [[ -n "${OSW_LOG_FILE:-}" ]]; then
    "$@" 2>&1 | tee -a "$OSW_LOG_FILE" >&2 || return "${PIPESTATUS[0]}"
  else
    "$@" >&2 || return $?
  fi
}

# qemu/binfmt precondition for building an aarch64 rootfs on a non-ARM host.
osw_check_binfmt() {
  local host
  host="$(osw_host_arch)"
  if [[ "$host" == "aarch64" || "$host" == "arm64" ]]; then
    osw_ok "host is $host: native chroot available"
    return 0
  fi
  osw_warn "host is $host: building an aarch64 rootfs requires qemu-user-static + binfmt_misc"
  if [[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
    osw_ok "binfmt_misc qemu-aarch64 handler is registered"
  else
    osw_error "binfmt_misc qemu-aarch64 is not registered"
    osw_info "Debian/Ubuntu: sudo apt install qemu-user-static && sudo systemctl restart systemd-binfmt"
    osw_info "Arch:         sudo pacman -S qemu-user-static-binfmt && sudo systemctl restart systemd-binfmt"
    return 1
  fi
}

# --- Manifest helpers ------------------------------------------------------
# Requires python3 >= 3.11 (tomllib). Emits tab-separated rows so bash can
# consume them without a TOML parser dependency.
osw_toml_rows() {
  local manifest="$1"
  osw_require_file "$manifest"
  python3 - "$manifest" <<'PY'
import sys
try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - python < 3.11
    sys.stderr.write("python3 >= 3.11 is required (tomllib)\n")
    raise SystemExit(2)

with open(sys.argv[1], "rb") as fh:
    data = tomllib.load(fh)

for comp in data.get("component", []):
    for entry in comp.get("files", []) or [{"name": ""}]:
        print("\t".join([
            str(comp.get("id", "")),
            str(comp.get("mode", "files")),
            str(comp.get("target", "boot")),
            str(comp.get("dest_dir", "/")),
            str(comp.get("source_dir", comp.get("id", ""))),
            "1" if comp.get("required", True) else "0",
            str(entry.get("name", "")),
            str(entry.get("sha256", "")),
            str(entry.get("bytes", 0)),
        ]))
PY
}

# --- Cleanup trap ----------------------------------------------------------
OSW_TMP_DIRS=()
osw_tmpdir() {
  local dir
  dir="$(mktemp -d)"
  OSW_TMP_DIRS+=("$dir")
  printf '%s' "$dir"
}
osw_cleanup() {
  local dir
  for dir in "${OSW_TMP_DIRS[@]:-}"; do
    if [[ -n "$dir" && -d "$dir" ]]; then
      rm -rf -- "$dir"
    fi
  done
  # Never let the EXIT trap change the script's exit status.
  return 0
}
trap osw_cleanup EXIT

# --- Direct invocation -----------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --print-config) osw_print_config ;;
    ""|--help|-h)
      cat <<'EOF'
OmarchySwitch shared library (sourced by scripts, not usually run directly)

Usage:
  common.sh --print-config   Print the effective configuration (defaults +
                             configs/local.conf + versions.lock)

Available helpers (see the file for details):
  osw_load_config, osw_require_cmds, osw_require_root, osw_confirm,
  osw_require_aarch64_tree, osw_assert_no_foreign_elf, osw_sha256,
  osw_check_binfmt, osw_toml_rows, osw_run_logged
EOF
      ;;
    *) osw_die "unknown argument: $1 (try --help)" ;;
  esac
fi
