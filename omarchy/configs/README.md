# `omarchy/configs/` — surcharges OmarchySwitch

Ces fichiers ne remplacent pas la configuration Omarchy : ils s'y ajoutent.

| Fichier | Destination | Appliqué par |
|---|---|---|
| `hypr/omarchyswitch.conf` | `~/.config/omarchyswitch/hyprland.conf` + `source` ajouté à `~/.config/hypr/hyprland.conf` | `omarchy/scripts/apply-configs.sh` |
| `environment.d/10-omarchyswitch.conf` | `/etc/environment.d/10-omarchyswitch.conf` | `scripts/install-desktop.sh` |

## Pourquoi une surcharge et pas une réécriture

Omarchy régénère et met à jour ses configurations. Remplacer
`~/.config/hypr/hyprland.conf` casserait ses mises à jour et ses thèmes.
Hyprland applique les directives dans l'ordre de lecture : ajouter un `source`
en fin de fichier suffit à faire gagner les surcharges pour les clés concernées.

`apply-configs.sh` écrit ce bloc, encadré de marqueurs, et le remplace au lieu de
l'empiler à chaque exécution :

```ini
# >>> omarchyswitch: switch overrides >>>
source = ~/.config/omarchyswitch/hyprland.conf
# <<< omarchyswitch: switch overrides <<<
```

## Ce que contient la surcharge Hyprland

- `monitor` : eDP-1 en 1280×720@60, échelle 1 ;
- `input:touchdevice:transform` : rotation tactile (valeur à ajuster sur la
  console) ;
- désactivation du flou et réduction des animations (GM20B) ;
- `misc:vfr` activé ;
- `cursor:no_hardware_cursors` — option souvent nécessaire sur Tegra, **à
  valider sur la console**.

Chaque ligne discutable est commentée dans le fichier avec la raison et la
valeur à tester.

## Ce que ces fichiers ne font pas

- Ils ne configurent aucun réseau, aucun mot de passe, aucune identité Git.
- Ils ne changent pas le terminal par défaut d'Omarchy : voir
  `desktop/terminal/README.md` pour ce choix.

## Appliquer manuellement

```bash
./omarchy/scripts/apply-configs.sh --home /home/switch --user switch --dry-run
./omarchy/scripts/apply-configs.sh --home /home/switch --user switch
```
