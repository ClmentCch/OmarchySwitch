# 01 — Architecture

## Couches

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Expérience utilisateur        Omarchy 4.5.0 (MIT)                    │
│                                Hyprland · Waybar · Walker · thèmes    │
├──────────────────────────────────────────────────────────────────────┤
│  Adaptations OmarchySwitch     surcharges Hyprland, environment.d,    │
│                                session uwsm, polices, terminal        │
├──────────────────────────────────────────────────────────────────────┤
│  Système utilisateur           Arch Linux ARM64 (pacman, systemd)     │
│                                rootfs overlay, unités, premier boot   │
├──────────────────────────────────────────────────────────────────────┤
│  Compatibilité matérielle      Switchroot : noyau L4T 4.9.140, DTB,   │
│                                modules, firmware, ATF, U-Boot         │
├──────────────────────────────────────────────────────────────────────┤
│  Amorçage                      hekate (L4T Loader) → RCM              │
├──────────────────────────────────────────────────────────────────────┤
│  Matériel                      Tegra X1 (T210), GM20B, BCM4356, ...   │
└──────────────────────────────────────────────────────────────────────┘
```

## Responsabilités par dossier

| Dossier | Responsabilité | Ne fait pas |
|---|---|---|
| `bootloader/` | Configuration hekate, entrées L4T, installation des fichiers de boot | Ne fournit pas hekate |
| `switchroot/` | Emplacements, manifeste, import et vérification des composants | Ne fournit pas les binaires |
| `archlinux/` | Bootstrap, pacman, overlay rootfs, paquets | Ne fournit pas de noyau |
| `hardware/` | Documentation et statut par sous-système | N'écrit pas de pilote |
| `omarchy/` | Upstream épinglé, surcharges, patches futurs | Ne forke pas Omarchy |
| `desktop/` | Détails de configuration du bureau | Ne remplace pas les paquets |
| `applications/` | Inventaire et méthode de portage | Ne prétend rien fonctionner |
| `installer/` | Écriture d'image, partitionnement | Ne s'exécute pas sur la console |
| `recovery/` | Diagnostic et restauration des fichiers de boot | Ne répare pas un rootfs |
| `build/` | Pipeline, manifestes, CI | Ne produit pas d'image « complète » |
| `scripts/` | Scripts utilisateur finaux | Ne cache pas les échecs |

## Flux de données

```text
Arch Linux ARM tarball ──┐
Omarchy packages ────────┤
                         ├──► rootfs ──┐
Switchroot components ───┘             ├──► image SD ──► carte ──► console
hekate release ────────────────────────┤
                                       └──► arbre de boot (FAT)
```

Chaque flèche est un script distinct, avec une vérification à l'entrée et une
vérification à la sortie. Aucun script ne fait deux choses sans le dire.

## Décisions et alternatives rejetées

| Décision | Alternative rejetée | Raison |
|---|---|---|
| Arch ARM comme base | Ubuntu Bionic Switchroot | Arch est la base d'Omarchy ; rolling release ; pacman |
| Chaîne hekate/L4T conservée | Chargeur maison, UEFI, kexec | Seule chaîne réellement supportée par le matériel |
| Surcharges Omarchy | Fork d'Omarchy | Suivi des mises à jour, surface de maintenance réduite |
| Aucun binaire versionné | Tout inclure pour un « one-click » | Licences NVIDIA, taille, traçabilité |
| Erista seulement | Erista + Mariko | PMIC, DVFS et support noyau différents |
| microSD seulement | Installation eMMC | Risque de rendre Horizon OS inutilisable |

## Voir aussi

- [02-boot-chain](02-boot-chain.md) — le détail du démarrage
- [ADR](adr/README.md) — décisions avec contexte et conséquences
