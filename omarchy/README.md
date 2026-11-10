# `omarchy/` — adaptation d'Omarchy 4.5.0 à la Switch

Omarchy fournit l'environnement (Hyprland, Waybar, Walker, thèmes, scripts).
Ce dossier ne copie **pas** Omarchy : il l'épingle, documente ce qui est
réutilisable, et ajoute une fine couche d'adaptation matérielle.

| Dossier | Rôle |
|---|---|
| `upstream/` | Références épinglées : dépôt, tag, licences, ce qui est repris ou écarté |
| `patches/` | Emplacement des patches à appliquer à Omarchy (aucun patch à ce jour) |
| `configs/` | Surcharges OmarchySwitch : Hyprland, `environment.d` |
| `scripts/apply-configs.sh` | Applique les surcharges dans le home utilisateur, de façon idempotente |

## Pourquoi ne pas utiliser l'ISO ARM64

L'ISO `omarchy-4.5.0-aarch64.iso` cible les machines NVIDIA ARM (DGX Spark,
N1X). Elle embarque :

- un chargeur d'amorçage (Limine) inutile ici : la Switch démarre par hekate ;
- le noyau `linux-omarchy`, qui n'a aucun support Tegra X1 ;
- un partitionnement et un initramfs incompatibles avec le bootstack Switchroot.

Copier cette ISO dans le rootfs produirait une image impossible à démarrer.
Le projet installe donc les **paquets** Omarchy `aarch64` depuis
`https://pkgs.omarchy.org/stable/aarch64/` (vérifié accessible le 2026-11-10),
puis applique ses propres configurations.

## Ce qui est repris d'Omarchy

- Le compositeur et son écosystème : Hyprland, Waybar, Walker, `uwsm`.
- Les paquets `omarchy`, `omarchy-settings` et leurs dépendances.
- Les conventions de configuration (`~/.config/omarchy/`, thèmes, polices).
- Les raccourcis clavier, à l'exception de ceux qui dépendent d'un clavier
  physique absent sur la console (voir `desktop/`).

## Ce qui est écarté

| Élément | Raison |
|---|---|
| `linux-omarchy` | Incompatible Tegra X1 ; remplacerait le noyau Switchroot |
| ISO ARM64 et son installateur | Chargeur et partitionnement inadaptés |
| Applications commerciales (Dropbox, Spotify natif, etc.) | Disponibilité `aarch64` non vérifiée sur cette plateforme |
| Gaming (Steam, Lutris) | Hors périmètre d'une base de développement |

## État

Les paquets sont installables, les configurations sont écrites, mais **aucune
session graphique n'a été lancée sur la console**. Voir
[`../docs/05-status-matrix.md`](../docs/05-status-matrix.md).
