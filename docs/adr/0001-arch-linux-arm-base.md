# 0001 — Arch Linux ARM64 comme système principal

- **Statut :** acceptée
- **Date :** 2026-11-10

## Contexte

Omarchy est une distribution Arch Linux. La base existante pour la Switch
(Switchroot) est Ubuntu Bionic/Jammy, avec un noyau L4T 4.9.140.

Trois voies étaient possibles :

1. garder Ubuntu et y ajouter Omarchy (impossible : Omarchy n'est pas un thème,
   c'est un ensemble de paquets Arch et de conventions systemd/Arch) ;
2. partir d'Arch Linux ARM et conserver les composants matériels Switchroot ;
3. partir d'une base minimaliste (Buildroot, Alpine) et tout reconstruire.

Le projet vise une véritable distribution avec Omarchy, pacman et un système
maintenu.

## Décision

Utiliser **Arch Linux ARM (aarch64)** comme système utilisateur :

- rootfs issu du tarball officiel `ArchLinuxARM-aarch64-latest.tar.gz` ;
- dépôts `core`, `extra`, `alarm`, `aur` ;
- paquets Omarchy `aarch64` depuis `pkgs.omarchy.org` ;
- overlay de configuration propre au projet.

Le noyau, les modules, le firmware, les DTBs, ATF et U-Boot restent ceux de
Switchroot : Arch ne fournit aucun support Tegra X1.

## Alternatives considérées

| Alternative | Rejetée parce que |
|---|---|
| Ubuntu + Omarchy | Omarchy n'existe pas pour Ubuntu ; ce serait un fork complet |
| Alpine / Buildroot | Pas de pacman, pas d'écosystème Omarchy, travail de maintenance énorme |
| Arch + noyau Arch | Aucun noyau Arch ne supporte le Tegra X1 avec écran/GPU |
| Gentoo | Compilation sur console trop lente, maintenance disproportionnée |

## Conséquences

**Positives**

- base cohérente avec Omarchy (pacman, systemd, conventions Arch) ;
- mises à jour continues, écosystème large ;
- AUR disponible pour les outils manquants.

**Négatives / risques**

- systemd 261 est incompatible avec le noyau 4.9 (ADR 0004) : c'est le risque
  principal, et il est bloquant ;
- la plupart des paquets Arch sont compilés pour x86_64 et doivent exister en
  aarch64 (c'est le cas pour le socle, pas pour tout) ;
- pas de noyau Arch : la dépendance à Switchroot reste totale pour le matériel.

**Mesures**

- vérification systématique de l'architecture (validation + `osw_assert_no_foreign_elf`) ;
- aucune dépendance à un paquet non disponible en aarch64 sans documentation.

## Références

- Arch Linux ARM : <https://archlinuxarm.org/>
- Omarchy : <https://github.com/omacom/omarchy>
- ADR 0004 : [`0004-systemd-kernel-compatibility.md`](0004-systemd-kernel-compatibility.md)
