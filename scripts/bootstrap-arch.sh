#!/usr/bin/env bash
#
# bootstrap-arch.sh — prepare the build host and download the Arch Linux ARM
# aarch64 bootstrap tarball.
#
# This script never boots anything and never touches a block device. It:
#   1. checks host prerequisites (tools, aarch64 build capability),
#   2. creates the build directories,
#   3. downloads the Arch Linux ARM aarch64 tarball into build/cache,
#   4. verifies its SHA-256 when one is pinned in configs/omarchyswitch.conf
#      (or in configs/local.conf),
#   5. optionally unpacks a pristine copy into build/src.
#
# Usage:
#   ./scripts/bootstrap-arch.sh [--check-only] [--allow-unpinned-tarball]
#                               [--unpack] [--force]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CHECK_ONLY=0
ALLOW_UNPINNED=0
UNPACK=0
FORCE=0
TARBALL=""

usage() {
  sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --check-only             Only verify prerequisites, download nothing.
  --allow-unpinned-tarball Accept a tarball whose SHA-256 is not pinned.
                           Prints the observed hash so it can be pinned.
  --unpack                 Also unpack the tarball into build/src/rootfs-src.
  --force                  Re-download even if a cached copy exists.
  -h, --help               Show this help.
EOF
}

while (( $# )); do
  case "$1" in
    --check-only) CHECK_ONLY=1 ;;
    --allow-unpinned-tarball) ALLOW_UNPINNED=1 ;;
    --unpack) UNPACK=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_target_arch

osw_step "Host prerequisites"
osw_require_cmds curl tar
[[ "$TARGET_ARCH" == "aarch64" ]] || osw_die "TARGET_ARCH must be aarch64 (got '$TARGET_ARCH')"

host_arch="$(osw_host_arch)"
osw_info "host architecture: $host_arch"
osw_info "target architecture: $TARGET_ARCH"

if ! osw_check_binfmt; then
  osw_warn "rootfs construction will not be possible until binfmt is available."
  osw_warn "Bootstrap/download checks continue."
fi

for tool in parted mkfs.ext4 mkfs.vfat zip unzip python3; do
  if osw_have "$tool"; then
    osw_ok "$tool present"
  else
    osw_warn "$tool missing (needed later for image build or packaging)"
  fi
done

if python3 -c 'import tomllib' >/dev/null 2>&1; then
  osw_ok "python3 tomllib available (manifest parsing)"
else
  osw_die "python3 >= 3.11 is required to parse switchroot/manifest.toml"
fi

if (( CHECK_ONLY )); then
  osw_ok "prerequisite check finished (no download requested)"
  exit 0
fi

osw_step "Build directories"
CACHE_DIR="$OSW_ROOT/build/cache"
SRC_DIR="$OSW_ROOT/build/src"
osw_ensure_dir "$CACHE_DIR"
osw_ensure_dir "$SRC_DIR"
osw_ensure_dir "$(osw_boot_tree)"
osw_ok "$CACHE_DIR"
osw_ok "$SRC_DIR"

osw_step "Arch Linux ARM bootstrap tarball"
TARBALL="$CACHE_DIR/$(basename "$ALARM_TARBALL_URL")"
expected_sha="${ALARM_TARBALL_SHA256:-}"

if [[ -f "$TARBALL" && "$FORCE" -ne 1 ]]; then
  osw_info "using cached tarball: $TARBALL"
else
  osw_info "downloading $ALARM_TARBALL_URL"
  tmp_download="$TARBALL.part"
  if ! curl -fL --retry "$FETCH_RETRIES" --connect-timeout 20 -o "$tmp_download" "$ALARM_TARBALL_URL"; then
    rm -f -- "$tmp_download"
    osw_die "download failed: $ALARM_TARBALL_URL"
  fi
  mv -f -- "$tmp_download" "$TARBALL"
fi

osw_require_file "$TARBALL"
observed_sha="$(osw_sha256 "$TARBALL")"
tarball_bytes="$(osw_file_bytes "$TARBALL")"
osw_info "tarball: $TARBALL ($((tarball_bytes / 1024 / 1024)) MiB)"
osw_info "sha256: $observed_sha"

if [[ -n "$expected_sha" ]]; then
  if [[ "$observed_sha" != "$expected_sha" ]]; then
    osw_die "SHA-256 mismatch for the Arch Linux ARM tarball
  expected: $expected_sha
  observed: $observed_sha
The upstream 'latest' tarball is regenerated regularly. If you trust this
download, pin the observed hash in configs/local.conf as ALARM_TARBALL_SHA256."
  fi
  osw_ok "SHA-256 matches the pinned value"
else
  if (( ALLOW_UNPINNED )); then
    osw_warn "no SHA-256 pinned: accepting the tarball because --allow-unpinned-tarball was given"
    osw_info "pin this value in configs/local.conf:"
    printf 'ALARM_TARBALL_SHA256="%s"\n' "$observed_sha"
  else
    osw_die "no SHA-256 pinned for the Arch Linux ARM tarball.
Re-run with --allow-unpinned-tarball once, then pin the printed hash in
configs/local.conf. This prevents silently building from a replaced tarball."
  fi
fi

# Arch Linux ARM publishes a detached PGP signature next to the tarball.
# We fetch it when available so the operator can verify it manually; the
# build itself relies on the pinned SHA-256.
sig_url="${ALARM_TARBALL_URL}.sig"
sig_file="${TARBALL}.sig"
if [[ ! -f "$sig_file" ]]; then
  if curl -fsSL --retry 2 --connect-timeout 15 -o "$sig_file" "$sig_url" 2>/dev/null; then
    osw_ok "detached signature cached: $sig_file"
    osw_info "verify with: gpg --verify '$sig_file' '$TARBALL' (ALARM signing key required)"
  else
    rm -f -- "$sig_file"
    osw_warn "no detached signature available at $sig_url (checksum pinning still applies)"
  fi
fi

if (( UNPACK )); then
  osw_step "Unpacking a pristine copy"
  unpack_dir="$SRC_DIR/rootfs-src"
  osw_require_empty_or_absent "$unpack_dir"
  tarball_mb=$((tarball_bytes / 1024 / 1024))
  osw_require_free_space "$SRC_DIR" $((tarball_mb * 4))
  osw_ensure_dir "$unpack_dir"
  osw_info "extracting into $unpack_dir"
  tar -xpf "$TARBALL" -C "$unpack_dir"
  osw_require_aarch64_tree "$unpack_dir"
  osw_ok "pristine aarch64 tree ready: $unpack_dir"
  osw_info "note: build-rootfs.sh extracts its own copy; this one is for inspection."
fi

osw_step "Next steps"
cat >&2 <<EOF
1. Pin the tarball hash in configs/local.conf if you have not already.
2. Place the Switchroot components described in switchroot/README.md.
3. Build the root filesystem:
     sudo ./scripts/build-rootfs.sh --output build/output/rootfs
EOF
osw_ok "bootstrap prerequisites satisfied"
