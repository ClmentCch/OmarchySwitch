# 00 — Vue d'ensemble

## Objectif

OmarchySwitch est une distribution Linux destinée à la **Nintendo Switch V1
(Erista)**. Elle combine :

- **Arch Linux ARM64** comme système principal (pacman, rolling release) ;
- **Omarchy 4.5.0** comme environnement de bureau (Hyprland, Waybar, Walker) ;
- **Switchroot** comme couche de compatibilité matérielle (noyau L4T 4.9.140,
  ATF, U-Boot, DTB, modules, firmware) ;
- **hekate** comme bootloader de première étape.

Ubuntu Bionic Switchroot n'est **pas** le système utilisateur. Seuls ses
composants matériels sont conservés.

## Ce que le projet n'est pas

| Ce n'est pas | Pourquoi |
|---|---|
| Un thème Omarchy pour Ubuntu | Le système utilisateur est Arch, pas Ubuntu |
| Un launcher | La distribution remplace le système, pas seulement l'interface |
| Une image prête à flasher | Aucun binaire matériel n'est redistribué ici |
| Un fork de Switchroot | Le projet ne modifie pas les binaires Switchroot |
| Un fork d'Omarchy | Les adaptations sont des surcharges de configuration |

## Utilisateur visé

Une personne possédant une Switch V1 non patchée en RCM, une carte microSD, un
PC Linux pour préparer la carte, et l'envie de comprendre ce qu'elle installe.
Le projet suppose une lecture de la documentation : ce n'est pas un installateur
en un clic.

## Contraintes structurantes

| Contrainte | Conséquence |
|---|---|
| Le noyau Switchroot est un L4T **4.9.140** | systemd 261 (Arch) ne peut pas démarrer → **blocage connu** |
| Les blobs NVIDIA ne sont pas redistribuables | Aucun binaire matériel dans le dépôt |
| La console n'a pas d'UART accessible | Diagnostic par écran (`fbconsole=0`) ou USB |
| 4 Gio de RAM partagés avec le GPU | Pas de scaling fractionnaire, effets réduits |
| RCM n'existe que sur Erista | Mariko est hors périmètre |
| La SD est lente et fragile | `noatime`, tmpfs, options ext4 compatibles 4.9 |

## Décisions majeures

1. **Arch Linux ARM comme base** — voir [ADR 0001](adr/0001-arch-linux-arm-base.md).
2. **Chaîne hekate → L4T Loader → ATF → U-Boot** — voir
   [ADR 0002](adr/0002-hekate-l4t-boot-chain.md).
3. **Aucun binaire versionné** — voir
   [ADR 0003](adr/0003-no-vendored-binaries.md).
4. **Compatibilité systemd traitée comme un problème, pas masquée** — voir
   [ADR 0004](adr/0004-systemd-kernel-compatibility.md).

## Hypothèses explicites

- La carte microSD est le média de démarrage.
- L'eMMC (Horizon OS) n'est jamais modifié par les scripts du projet.
- L'utilisateur sait entrer en RCM et injecter hekate.
- Le matériel est fonctionnel (aucun test de réparation matérielle).

## Où commencer

1. [`05-status-matrix.md`](05-status-matrix.md) : ce qui marche vraiment.
2. [`09-remaining-work.md`](09-remaining-work.md) : ce qu'il vous reste à faire.
3. [`03-build.md`](03-build.md) : construire.
