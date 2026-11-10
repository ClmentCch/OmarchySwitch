#!/usr/bin/env bash
#
# package-release.sh — build the distributable project archive.
#
# Output: dist/OmarchySwitch-Base-v<VERSION>.zip
# The archive contains a single top-level directory, omarchyswitch/, with the
# complete project base: scripts, configurations, manifests and documentation.
#
# Excluded: .git, dist/, build outputs and caches, local overrides
# (configs/local.conf), downloaded upstream sources, hardware binaries and
# anything ignored by .gitignore. No secret and no non-redistributable binary
# is included.
#
# Usage:
#   ./scripts/package-release.sh [--output FILE] [--keep-stage] [--verify-only FILE]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

OUTPUT=""
KEEP_STAGE=0
VERIFY_ONLY=""

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --output FILE       Archive path (default dist/OmarchySwitch-Base-v<VERSION>.zip).
  --keep-stage        Keep dist/stage/ for inspection.
  --verify-only FILE  Only verify an existing archive.
  -h, --help          This help.
EOF
}

while (( $# )); do
  case "$1" in
    --output) OUTPUT="${2:-}"; [[ -n "$OUTPUT" ]] || osw_die "--output needs a file"; shift ;;
    --keep-stage) KEEP_STAGE=1 ;;
    --verify-only) VERIFY_ONLY="${2:-}"; [[ -n "$VERIFY_ONLY" ]] || osw_die "--verify-only needs a file"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_cmds zip unzip python3 sha256sum

verify_archive() {
  local archive="$1"
  osw_require_file "$archive"
  osw_step "Verifying $archive"
  if ! unzip -tq "$archive" >/dev/null; then
    osw_die "archive is corrupt: $archive"
  fi
  osw_ok "zip integrity: ok"

  # Capture the listing once: piping `unzip -Z1` into `grep -q` makes grep exit
  # on first match, SIGPIPE kills unzip and `pipefail` reports a false negative.
  local listing count
  listing="$(unzip -Z1 "$archive")"
  count="$(printf '%s\n' "$listing" | wc -l | tr -d ' ')"
  osw_info "entries: $count"

  # Every entry must live under omarchyswitch/
  local bad_prefix
  bad_prefix="$(grep -vE '^omarchyswitch/' <<<"$listing" | head -5 || true)"
  if [[ -n "$bad_prefix" ]]; then
    osw_die "entries outside omarchyswitch/: $bad_prefix"
  fi
  osw_ok "single top-level directory: omarchyswitch/"

  # Things that must never ship.
  local forbidden
  forbidden="$(grep -E '(^|/)(\.git/|local\.conf$|\.env$|id_rsa|\.pem$|\.pkg\.tar)' <<<"$listing" | head -5 || true)"
  if [[ -n "$forbidden" ]]; then
    osw_die "forbidden entry in archive: $forbidden"
  fi
  osw_ok "no VCS directory, local override, secret file or package payload"

  # Required entries.
  local required entry missing=0
  for entry in \
      omarchyswitch/README.md \
      omarchyswitch/VERSION \
      omarchyswitch/LICENSE \
      omarchyswitch/scripts/validate-architecture.sh \
      omarchyswitch/bootloader/hekate_ipl.ini \
      omarchyswitch/switchroot/manifest.toml \
      omarchyswitch/docs/00-overview.md; do
    if grep -Fxq "$entry" <<<"$listing"; then
      :
    else
      osw_error "missing from archive: $entry"
      missing=$((missing + 1))
    fi
  done
  (( missing == 0 )) || osw_die "$missing required entry/entries missing"
  osw_ok "required entries present"

  # Executable bit preserved for scripts (read the stored mode, no pipe).
  local mode_line
  mode_line="$(unzip -Z "$archive" omarchyswitch/scripts/validate-architecture.sh | awk '/^-/ {print; exit}')"
  if [[ "$mode_line" == -rwx* ]]; then
    osw_ok "executable bits preserved"
  else
    osw_warn "executable bit not preserved for shell scripts (mode: ${mode_line:0:10})"
  fi

  local bytes digest
  bytes="$(osw_file_bytes "$archive")"
  digest="$(osw_sha256 "$archive")"
  osw_ok "$(basename -- "$archive"): $((bytes / 1024)) KiB"
  osw_info "sha256: $digest"
  printf '%s  %s\n' "$digest" "$(basename -- "$archive")"
}

if [[ -n "$VERIFY_ONLY" ]]; then
  verify_archive "$VERIFY_ONLY"
  exit 0
fi

cd -- "$OSW_ROOT"

OUTPUT="${OUTPUT:-dist/OmarchySwitch-Base-v${DISTRO_VERSION}.zip}"
OUTPUT="$(realpath -m -- "$OUTPUT")"
STAGE_ROOT="$(dirname -- "$OUTPUT")/stage"
STAGE="$STAGE_ROOT/omarchyswitch"

osw_step "Staging"
rm -rf -- "$STAGE_ROOT"
osw_ensure_dir "$STAGE"

# Copy the working tree, excluding everything that must not ship.
# A plain rsync-like copy is used instead of `git archive` so that a
# developer's uncommitted changes are also packaged (and reported).
EXCLUDES=(
  '.git' '.git/*' 'dist' 'dist/*' 'build/output' 'build/output/*'
  'build/cache' 'build/cache/*' 'build/src' 'build/src/*'
  'configs/local.conf' 'omarchy/upstream/src' 'omarchy/upstream/src/*'
  '*.img' '*.img.*' '*.zip' '*.pkg.tar.*' '*.log'
)
rsync_args=(--recursive --links --perms --times --exclude='*.tmp')
for pattern in "${EXCLUDES[@]}"; do
  rsync_args+=("--exclude=$pattern")
done
if osw_have rsync; then
  rsync "${rsync_args[@]}" ./ "$STAGE/"
else
  # Fallback without rsync: tar with the same exclusion list.
  tar_excludes=()
  for pattern in "${EXCLUDES[@]}"; do
    tar_excludes+=("--exclude=$pattern")
  done
  tar -C . -cf - "${tar_excludes[@]}" . | tar -C "$STAGE" -xf -
fi

# Switchroot hardware directories must exist (with their README) but their
# payloads never ship, even if present locally.
for dir in kernel dtb modules firmware boot; do
  find "$STAGE/switchroot/$dir" -mindepth 1 -maxdepth 1 -not -name 'README.md' -exec rm -rf {} + 2>/dev/null || true
done
find "$STAGE" -name 'manifest.local.toml' -delete 2>/dev/null || true

osw_ok "staged $(find "$STAGE" -type f | wc -l | tr -d ' ') files"

# Uncommitted changes are worth flagging: an archive that does not match HEAD
# is still valid, but the operator should know.
if osw_have git && git -C "$OSW_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if [[ -n "$(git -C "$OSW_ROOT" status --porcelain)" ]]; then
    osw_warn "working tree has uncommitted changes: this archive is not reproducible from HEAD"
  else
    osw_ok "working tree matches HEAD"
  fi
  git -C "$OSW_ROOT" rev-parse HEAD > "$STAGE/BUILD-COMMIT" 2>/dev/null || true
fi
printf 'archived_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STAGE/BUILD-STAMP"

osw_step "Creating archive"
osw_ensure_dir "$(dirname -- "$OUTPUT")"
rm -f -- "$OUTPUT"
if ! ( cd -- "$STAGE_ROOT" && zip -r -9 -X -q "$OUTPUT" omarchyswitch ); then
  osw_die "zip failed"
fi
osw_ok "$OUTPUT"

if (( ! KEEP_STAGE )); then
  rm -rf -- "$STAGE_ROOT"
fi

verify_archive "$OUTPUT" | tee "$OUTPUT.sha256"
osw_ok "package-release finished"
