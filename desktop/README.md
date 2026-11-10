# `desktop/` — expérience de bureau Omarchy sur Switch

Objectif : conserver l'expérience Omarchy (Hyprland + Waybar + Walker + thèmes)
en l'adaptant à un écran 720p tactile et à un GPU GM20B.

| Dossier | Sujet | Rôle |
|---|---|---|
| `hyprland/` | compositeur | surcharge de configuration, gestion tactile et écran |
| `waybar/` | barre d'état | configuration de référence adaptée à la console |
| `walker/` | lanceur | notes d'adaptation (clavier vs tactile) |
| `terminal/` | terminal | choix et justification (`foot` par défaut) |
| `themes/` | thèmes | comment appliquer un thème Omarchy, sans le forker |
| `fonts/` | polices | liste de paquets et rendu à l'échelle 1 |

## Chaîne logicielle

```text
uwsm (gestion de session Wayland)
  └─ Hyprland (compositeur)
       ├─ Waybar (barre)
       ├─ Walker (lanceur)
       ├─ foot (terminal)
       └─ applications Omarchy
```

## Contraintes propres à la console

| Contrainte | Conséquence sur la configuration |
|---|---|
| Dalle 1280×720 | échelle 1, pas de scaling fractionnaire, polices dimensionnées à la main |
| GPU GM20B | flou désactivé, animations raccourcies, VFR activé |
| Pas de clavier physique | les raccourcis seuls ne suffisent pas : un lanceur tactile est nécessaire |
| Tactile | rotation de l'axe tactile à accorder avec la rotation de l'écran |
| Batterie | veille et luminosité dépendent du noyau (voir `hardware/.../power/`) |

## Ce qui est installé par les scripts

- `scripts/install-desktop.sh` : paquets (Hyprland, Waybar, Walker, foot,
  NetworkManager, BlueZ, PipeWire), services, autologin tty1 + uwsm.
- `omarchy/scripts/apply-configs.sh` : surcharges Hyprland et `environment.d`.

## Ce qui n'est pas encore fait

Aucune session graphique n'a été lancée sur une console. Les configurations
écrites ici sont des points de départ documentés, pas des réglages validés.
