# Waybar sur Switch

Waybar est fourni par Omarchy avec sa propre configuration. Ce dossier contient
une **configuration de référence** pour la console, pas un remplacement.

| Fichier | Usage |
|---|---|
| `config.switch.jsonc` | modules utiles sur console : batterie, luminosité, réseau, Bluetooth, audio, horloge |

## Pourquoi ne pas l'activer automatiquement

Waybar est intégralement piloté par le fichier de configuration : remplacer
`~/.config/waybar/config.jsonc` par celui-ci supprimerait les modules Omarchy
(workspaces, notifications, mises à jour, thème). La bonne approche est de
fusionner les modules souhaités.

`omarchy/scripts/apply-configs.sh --desktop` copie donc ce fichier en
`~/.config/omarchyswitch/waybar-config.switch.jsonc` et laisse l'utilisateur
choisir.

## Modules spécifiques à la console

| Module | Commande | Dépendance |
|---|---|---|
| `battery` | intégré | `upower` ou `/sys/class/power_supply` |
| `backlight` | intégré | `/sys/class/backlight/*` (noyau + DTB) |
| `network` | intégré | NetworkManager |
| `bluetooth` | intégré | BlueZ + `bluetooth.service` |
| `wireplumber` | intégré | PipeWire/WirePlumber |
| `temperature` | intégré | capteurs Tegra (`thermal_zone*`) |

Si un module reste vide, c'est que la source n'existe pas : vérifier le
sous-système correspondant dans `hardware/aarch64-tegra-x1/` avant d'accuser
Waybar.

## Style

Le style (CSS) vient d'Omarchy et de son thème courant. Ne pas le dupliquer ici :
un thème Omarchy doit rester applicable sans modification.
