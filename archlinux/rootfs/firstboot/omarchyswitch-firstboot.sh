#!/usr/bin/env bash
#
# omarchyswitch-firstboot — one-shot setup executed on the console.
#
# Installed as /usr/local/sbin/omarchyswitch-firstboot and started by
# omarchyswitch-firstboot.service on the first boot only.
#
# Design constraints:
#   * no interaction: a handheld has no keyboard at boot and a console UI would
#     block the session forever;
#   * idempotent: every step checks its precondition and never fails the boot;
#   * no network required: the Wi-Fi firmware may be missing on a fresh card;
#   * never sets a password: the default account stays locked until the user
#     sets one deliberately.

set -uo pipefail

STATE_DIR="/var/lib/omarchyswitch"
MARKER="$STATE_DIR/.firstboot-done"
LOG="/var/log/omarchyswitch-firstboot.log"
CONF="/etc/omarchyswitch/build-info"

mkdir -p "$STATE_DIR"
: > "$LOG"
exec >>"$LOG" 2>&1

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

log "OmarchySwitch first boot started"

# --- 1. Grow the root filesystem to fill the card --------------------------
root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
if [[ -n "$root_src" && -b "$root_src" ]]; then
  log "root device: $root_src"
  if command -v resize2fs >/dev/null 2>&1; then
    if resize2fs "$root_src" >>"$LOG" 2>&1; then
      log "root filesystem grown to the partition size"
    else
      log "resize2fs failed (partition may already fill the device)"
    fi
  fi
else
  log "root is not a block device ($root_src); skipping resize"
fi

# --- 2. machine-id ---------------------------------------------------------
if [[ ! -s /etc/machine-id ]]; then
  if command -v systemd-machine-id-setup >/dev/null 2>&1; then
    systemd-machine-id-setup >>"$LOG" 2>&1 && log "machine-id generated"
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > /etc/machine-id
    log "machine-id generated without systemd helper"
  fi
else
  log "machine-id already present"
fi

# --- 3. Identity -----------------------------------------------------------
hostname_value="$(cat /etc/hostname 2>/dev/null || echo omarchyswitch)"
if [[ -n "$hostname_value" ]]; then
  hostnamectl set-hostname "$hostname_value" >>"$LOG" 2>&1 || \
    printf '%s\n' "$hostname_value" > /proc/sys/kernel/hostname
  log "hostname: $hostname_value"
fi

# --- 4. Advisory checks (never fatal) --------------------------------------
if [[ -f "$CONF" ]]; then
  log "build info:"
  sed 's/^/    /' "$CONF" >>"$LOG"
fi

if ! ls /usr/lib/modules >/dev/null 2>&1 || [[ -z "$(ls -A /usr/lib/modules 2>/dev/null)" ]]; then
  log "WARNING: no kernel modules installed — Wi-Fi, Bluetooth, audio and Joy-Con will not work"
fi

for fw in brcmfmac4356-pcie.bin brcmfmac4356-pcie.txt; do
  if ! find /lib/firmware -name "$fw" -print -quit 2>/dev/null | grep -q .; then
    log "WARNING: firmware missing: $fw (Wi-Fi will not work)"
  fi
done

if ! command -v Hyprland >/dev/null 2>&1 && ! command -v hyprland >/dev/null 2>&1; then
  log "NOTE: Hyprland is not installed; the graphical session will not start"
fi

# --- 5. User guidance ------------------------------------------------------
for home in /home/*; do
  [[ -d "$home" ]] || continue
  note="$home/FIRST-BOOT.md"
  if [[ ! -f "$note" ]]; then
    cat > "$note" <<'EOF'
# OmarchySwitch — premier démarrage

Votre compte est volontairement **verrouillé** : aucun mot de passe par défaut
n'existe. Définissez-en un depuis une console :

    sudo passwd "$USER"

Puis connectez le Wi-Fi :

    nmcli device wifi list
    nmcli device wifi connect "<SSID>" password "<mot de passe>"

Lancer la session graphique :

    uwsm start -S -D hyprland-uwsm.desktop

Si l'écran reste noir, consultez `docs/06-known-limitations.md` du dépôt :
plusieurs causes connues produisent ce symptôme (noyau/modules désaccordés,
firmware absent, DTB incorrect).

Rappel : cette version est une base de développement, pas une distribution
stable.
EOF
    chown --reference="$home" "$note" 2>/dev/null || true
    log "guidance written: $note"
  fi
done

# --- 6. Finish -------------------------------------------------------------
printf 'completed_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$MARKER"
sync

if command -v systemctl >/dev/null 2>&1; then
  systemctl disable omarchyswitch-firstboot.service >>"$LOG" 2>&1 || true
fi

log "first boot finished"
exit 0
