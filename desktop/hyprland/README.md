# Hyprland sur Switch

## Approche

Ne pas réécrire la configuration d'Omarchy. Empiler une surcharge :

```text
~/.config/hypr/hyprland.conf          (Omarchy)
  └─ source = ~/.config/omarchyswitch/hyprland.conf   (OmarchySwitch)
```

La surcharge réelle est
[`../../omarchy/configs/hypr/omarchyswitch.conf`](../../omarchy/configs/hypr/omarchyswitch.conf),
installée par `omarchy/scripts/apply-configs.sh`.

## Réglages clés

| Réglage | Valeur | Pourquoi |
|---|---|---|
| `monitor` | `eDP-1, 1280x720@60, 0x0, 1` | dalle 720p, échelle 1 |
| `monitor` (second) | `, preferred, auto, 1` | dock/HDMI |
| `decoration:blur:enabled` | `false` | effet le plus coûteux sur GM20B |
| `misc:vfr` | `true` | moins de travail quand rien ne bouge |
| `input:touchdevice:transform` | `1` (à tester) | rotation tactile |

## Raccourcis

Omarchy fournit les raccourcis. Deux adaptations sont probables sur console :

- les raccourcis qui supposent un clavier physique restent utiles avec un
  clavier USB/Bluetooth, mais ne sont pas découvrables au doigt ;
- un lanceur tactile (Walker) doit être accessible depuis la barre.

Ne pas modifier les raccourcis avant d'avoir testé la session : Omarchy les
fait évoluer et un fork local complique les mises à jour.

## Lancement de la session

`install-desktop.sh` configure :

```bash
# /etc/systemd/system/getty@tty1.service.d/autologin.conf
ExecStart=-/sbin/agetty --autologin switch --noclear %I $TERM
```

puis, dans `~/.bash_profile` de l'utilisateur :

```bash
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec uwsm start -S -D hyprland-uwsm.desktop
fi
```

L'autologin est un choix assumé : une console portable n'a pas de clavier au
démarrage. La sécurité repose sur l'accès physique, comme sur Horizon OS.

## Diagnostic

| Symptôme | Cause probable |
|---|---|
| Retour au prompt après `uwsm start` | EGL/GBM indisponible (pilote GPU absent) |
| Écran noir avec curseur | rotation/scale incohérents avec le panneau |
| Tactile décalé | `transform` incorrect |
| Lenteur générale | flou/animations encore actifs, ou rendu logiciel |

Journaux utiles : `journalctl --user -u uwsm*`, `cat /tmp/hypr/*.log`.
