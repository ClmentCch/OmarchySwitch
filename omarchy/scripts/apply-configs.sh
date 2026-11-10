#!/usr/bin/env bash
#
# apply-configs.sh — install the OmarchySwitch overrides into a user's home.
#
# Idempotent: running it twice produces the same result. It never replaces an
# Omarchy file; it appends (or refreshes) a clearly marked block that sources
# the override file.
#
# What it writes:
#   <home>/.config/omarchyswitch/hyprland.conf        (from omarchy/configs/hypr/)
#   <home>/.config/hypr/hyprland.conf                 (marked source line only)
#   <home>/.config/omarchy/omarchyswitch/README.md    (short explanation)
#
# Usage:
#   ./omarchy/scripts/apply-configs.sh --home /home/switch [--user switch]
#                                      [--desktop] [--dry-run]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

HOME_DIR=""
TARGET_USER=""
DESKTOP=0
DRY_RUN=0

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --home) HOME_DIR="${2:-}"; [[ -n "$HOME_DIR" ]] || osw_die "--home needs a directory"; shift ;;
    --user) TARGET_USER="${2:-}"; [[ -n "$TARGET_USER" ]] || osw_die "--user needs a value"; shift ;;
    --desktop) DESKTOP=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

[[ -n "$HOME_DIR" ]] || osw_die "--home is required"
HOME_DIR="$(realpath -m -- "$HOME_DIR")"
osw_require_dir "$HOME_DIR"

CONFIG_SRC="$OSW_ROOT/omarchy/configs"
CONFIG_DST="$HOME_DIR/.config/omarchyswitch"
HYPR_CONF="$HOME_DIR/.config/hypr/hyprland.conf"
BEGIN_MARKER="# >>> omarchyswitch: switch overrides >>>"
END_MARKER="# <<< omarchyswitch: switch overrides <<<"

osw_step "OmarchySwitch overrides -> $CONFIG_DST"
if (( DRY_RUN )); then
  osw_info "dry run: would create $CONFIG_DST and install hyprland.conf"
else
  osw_ensure_dir "$CONFIG_DST"
  install -Dm644 "$CONFIG_SRC/hypr/omarchyswitch.conf" "$CONFIG_DST/hyprland.conf"
  cat > "$CONFIG_DST/README.md" <<'EOF'
# OmarchySwitch overrides

`hyprland.conf` is sourced at the end of `~/.config/hypr/hyprland.conf` by a
marked block. It only sets keys that must differ on the Switch (panel mode,
touch rotation, GPU-friendly effects).

To remove the overrides: delete this directory and the block between
`# >>> omarchyswitch: switch overrides >>>` and
`# <<< omarchyswitch: switch overrides <<<` in
`~/.config/hypr/hyprland.conf`.
EOF
  if [[ -n "$TARGET_USER" ]] && [[ "$(id -u "$TARGET_USER" 2>/dev/null || echo '')" != "" ]]; then
    chown -R "$TARGET_USER": "$CONFIG_DST" 2>/dev/null || \
      osw_warn "could not change ownership of $CONFIG_DST (run inside the rootfs?)"
  fi
  osw_ok "override file installed"
fi

osw_step "Hyprland include block"
if (( DRY_RUN )); then
  osw_info "dry run: would ensure the marked source block in $HYPR_CONF"
else
  osw_ensure_dir "$(dirname -- "$HYPR_CONF")"
  if [[ ! -f "$HYPR_CONF" ]]; then
    osw_warn "no existing $HYPR_CONF (Omarchy not installed yet?)"
    osw_info "creating a minimal config that sources the overrides"
    cat > "$HYPR_CONF" <<EOF
# Created by OmarchySwitch: Omarchy's configuration was not present.
\$mod = SUPER
$BEGIN_MARKER
source = ~/.config/omarchyswitch/hyprland.conf
$END_MARKER
EOF
  else
    if grep -qF "$BEGIN_MARKER" "$HYPR_CONF"; then
      # Refresh the block in place (keeps the file otherwise untouched).
      python3 - "$HYPR_CONF" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
import sys, pathlib
path = pathlib.Path(sys.argv[1])
begin, end = sys.argv[2], sys.argv[3]
text = path.read_text()
start = text.index(begin)
stop = text.index(end) + len(end)
block = begin + "\nsource = ~/.config/omarchyswitch/hyprland.conf\n" + end
path.write_text(text[:start] + block + text[stop:])
PY
      osw_ok "existing block refreshed"
    else
      {
        printf '\n%s\n' "$BEGIN_MARKER"
        printf '%s\n' 'source = ~/.config/omarchyswitch/hyprland.conf'
        printf '%s\n' "$END_MARKER"
      } >> "$HYPR_CONF"
      osw_ok "source block appended"
    fi
  fi
  if [[ -n "$TARGET_USER" ]] && [[ "$(id -u "$TARGET_USER" 2>/dev/null || echo '')" != "" ]]; then
    chown "$TARGET_USER": "$HYPR_CONF" 2>/dev/null || true
  fi
fi

if (( DESKTOP )); then
  osw_step "Desktop extras"
  if (( DRY_RUN )); then
    osw_info "dry run: would copy the Waybar reference config"
  else
    install -Dm644 "$OSW_ROOT/desktop/waybar/config.switch.jsonc" \
      "$CONFIG_DST/waybar-config.switch.jsonc"
    osw_ok "Waybar reference config: $CONFIG_DST/waybar-config.switch.jsonc"
    osw_info "it is NOT active by default: merge the modules you want into ~/.config/waybar/config.jsonc"
  fi
fi

if (( DRY_RUN )); then
  osw_ok "dry run finished"
else
  osw_ok "configurations applied to $HOME_DIR"
fi
