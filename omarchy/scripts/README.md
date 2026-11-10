# `omarchy/scripts/`

## `apply-configs.sh`

Installe les surcharges OmarchySwitch dans le home d'un utilisateur.

```bash
# Simulation
./omarchy/scripts/apply-configs.sh --home /home/switch --user switch --dry-run

# Application (root nécessaire si le home appartient à un autre utilisateur)
sudo ./omarchy/scripts/apply-configs.sh --home /home/switch --user switch --desktop
```

Ce qu'il écrit :

| Cible | Contenu |
|---|---|
| `~/.config/omarchyswitch/hyprland.conf` | surcharge Hyprland (écran, tactile, effets) |
| `~/.config/omarchyswitch/README.md` | explication et procédure de retrait |
| `~/.config/hypr/hyprland.conf` | bloc marqué `source = ~/.config/omarchyswitch/hyprland.conf` |
| `~/.config/omarchyswitch/waybar-config.switch.jsonc` | (avec `--desktop`) configuration Waybar de référence, non activée |

## Idempotence

Le bloc est remplacé, pas empilé : exécuter le script dix fois donne le même
résultat qu'une fois. Si `~/.config/hypr/hyprland.conf` n'existe pas (Omarchy pas
encore installé), le script en crée un minimal qui source les surcharges.

## Ce qu'il ne fait pas

- Il ne remplace jamais un fichier Omarchy complet.
- Il ne touche pas aux thèmes, aux polices ni aux raccourcis.
- Il ne modifie pas les fichiers système (`/etc`), qui sont gérés par
  `scripts/install-desktop.sh`.
