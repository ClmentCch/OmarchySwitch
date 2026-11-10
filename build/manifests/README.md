# `build/manifests/` — listes de paquets et contenu attendu

Ces fichiers sont lus par les scripts de construction. Ils sont la source de
vérité : modifier un paquet se fait ici, pas dans un script.

| Fichier | Lu par | Contenu |
|---|---|---|
| `base-packages.txt` | `scripts/build-rootfs.sh` | Socle Arch Linux ARM |
| `omarchy-packages.txt` | `scripts/integrate-omarchy.sh` | Paquets Omarchy (dépôt aarch64) |
| `desktop-packages.txt` | `scripts/install-desktop.sh` | Compositeur, barre, lanceur, terminal |
| `runtime-files.toml` | documentation, contrôle manuel | Contenu attendu de la partition FAT |

## Format des listes

Une entrée par ligne, premier champ = nom du paquet Arch :

```text
# commentaire
hyprland            # compositeur
waybar              # barre d'état
```

Le second champ (commentaire libre) est ignoré par les scripts mais utile en
relecture. Les lignes vides et `#` sont ignorées.

## Règle : échouer bruyamment

Les scripts utilisent `pacman -S --needed` sans masquer les erreurs. Un paquet
absent du miroir ARM fait échouer la construction avec le nom du paquet. C'est
volontaire : un système silencieusement incomplet est plus difficile à
diagnostiquer qu'un build qui s'arrête.

Si un paquet existe sur Arch x86_64 mais pas sur Arch Linux ARM, deux options :

1. le retirer de la liste (et documenter pourquoi) ;
2. l'ajouter à `archlinux/packages/` comme paquet construit localement.

## Vérification

```bash
./scripts/validate-architecture.sh
# et, pour un contrôle de disponibilité sans construire :
#   (dans un rootfs aarch64) pacman -Si $(grep -vE '^\s*(#|$)' build/manifests/base-packages.txt)
```
