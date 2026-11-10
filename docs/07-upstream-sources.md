# 07 — Sources upstream

Vérifié le **2026-11-10**. Les versions épinglées sont dans
`configs/versions.lock` ; les licences dans `THIRD-PARTY.md`.

## Omarchy

| | |
|---|---|
| Dépôt | <https://github.com/omacom/omarchy> |
| Tag | `v4.5.0` (release du 2026-11-04) |
| Licence | MIT |
| Paquets aarch64 | <https://pkgs.omarchy.org/stable/aarch64/> |
| ISO ARM64 | <https://iso.omarchy.org/omarchy-4.5.0-aarch64.iso> (non utilisée) |
| Site / manuel | <https://omarchy.org/>, `manual/` du dépôt |

Notes vérifiées :

- le paquet `omarchy-4.5.0-3-aarch64.pkg.tar.zst` est accessible (HTTP 200) ;
- l'ISO ARM64 est accessible (HTTP 200) mais inadaptée à la Switch ;
- le noyau `linux-omarchy` ne cible pas Tegra X1.

## Switchroot

| Composant | Dépôt | Branche/tag |
|---|---|---|
| Noyau L4T 4.9 | <https://gitlab.com/switchroot/kernel/l4t-kernel-4.9> | `lineage-19.1`, tag `linux-5.1.0_r2` |
| Plateforme T210 | <https://gitlab.com/switchroot/kernel/l4t-platform-t210-switch> | `linux-5.0.0-dev` |
| Overlays DT | <https://gitlab.com/switchroot/kernel/l4t-device-tree-overlays> | `master` |
| Initramfs | <https://gitlab.com/switchroot/kernel/l4t-initramfs> | `master` |
| Noyau mainline (WIP) | <https://gitlab.com/switchroot/kernel/mainline-kernel> | `switch-dev` |
| U-Boot | <https://gitlab.com/switchroot/bootstack/switch-uboot> | `linux-hekatf` |
| Scripts U-Boot | <https://gitlab.com/switchroot/bootstack/switch-uboot-scripts> | `master` |
| ATF | <https://gitlab.com/switchroot/bootstack/switch-atf> | `switch-v4-atf2.6` |
| Build scripts noyau | <https://gitlab.com/switchroot/kernel/l4t-kernel-build-scripts> | `master` |
| Wiki | <https://wiki.switchroot.org/wiki/linux> | — |

Licences : noyau GPL-2.0, ATF BSD-3-Clause, U-Boot GPL-2.0-or-later, blobs
NVIDIA propriétaires.

## hekate

| | |
|---|---|
| Dépôt | <https://github.com/CTCaer/hekate> |
| Version | `v6.5.4` |
| Licence | GPL-2.0 |
| Documentation des clés | `README.md` du dépôt |

## Arch Linux ARM

| | |
|---|---|
| Site | <https://archlinuxarm.org/> |
| Tarball | <https://archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz> |
| Miroirs | `http://mirror.archlinuxarm.org/$arch/$repo` |
| Dépôts | `core`, `extra`, `alarm`, `aur` |
| Licence | par paquet |

Note : le tarball « latest » est régénéré ; son empreinte doit être épinglée
localement.

## Travaux de référence

| Projet | Apport | Statut ici |
|---|---|---|
| `alarm-tegra-x1` (<https://notdouble.com/p/alarm-tegra-x1>) | Bring-up Arch ARM mainline sur HAC-001, patches, structure d'image | Référence documentaire, non intégré |
| L4S / Linux 4 Switch (<https://azka.li/linux-4-switch>) | Distribution Fedora sur noyau L4T, noyau maintenu | Référence ; son noyau 4.9.140 reste trop ancien pour systemd |
| NH Switch Guide | Procédures d'installation, avertissement sur Arch L4S déprécié | Référence de procédure |

## Ce qui a été explicitement écarté

| Élément | Raison |
|---|---|
| ISO Omarchy ARM64 | Chargeur/noyau/partitionnement inadaptés |
| `linux-omarchy` | Pas de support Tegra X1 |
| Noyau mainline « nu » | Pas de pilote d'écran, pas de console série |
| Paquets Ubuntu `.deb` | Incompatibles Arch (glibc, chemins NVIDIA) |
| Empaquetage des blobs NVIDIA | Interdit par leurs termes |
