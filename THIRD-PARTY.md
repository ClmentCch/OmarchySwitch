# Composants tiers : provenance et licences

Ce fichier recense tout ce que le projet utilise, référence ou intègre.
**Aucun de ces composants n'est redistribué dans ce dépôt** sauf mention
explicite ; les scripts les récupèrent depuis les sources officielles.

## Récapitulatif

| Composant | Rôle | Dépôt / source | Licence | Redistribué ici ? |
|---|---|---|---|---|
| Omarchy | Environnement et configuration du bureau | https://github.com/omacom/omarchy (tag `v4.5.0`) | MIT | Non (patchs et configs propres uniquement) |
| Omarchy packages | Paquets `omarchy*` aarch64 | https://pkgs.omarchy.org/stable/aarch64/ | MIT (paquets) | Non |
| Arch Linux ARM | Rootfs et dépôts aarch64 | https://archlinuxarm.org/ | Licences libres par paquet | Non |
| hekate | Bootloader / L4T Loader | https://github.com/CTCaer/hekate (tag `v6.5.4`) | GPL-2.0 | Non |
| Switchroot L4T kernel | Noyau 4.9.140 Tegra X1 | https://gitlab.com/switchroot/kernel/l4t-kernel-4.9 | GPL-2.0 | Non |
| Switchroot ATF | TrustZone / lance U-Boot | https://gitlab.com/switchroot/bootstack/switch-atf | BSD-3-Clause | Non |
| Switchroot U-Boot | Charge noyau, initramfs, DT | https://gitlab.com/switchroot/bootstack/switch-uboot | GPL-2.0-or-later | Non |
| Switchroot initramfs | Montage du rootfs, `switch_root` | https://gitlab.com/switchroot/kernel/l4t-initramfs | GPL-2.0 | Non |
| Switchroot device trees | DTBs / overlays Tegra 210 | https://gitlab.com/switchroot/kernel/l4t-device-tree-overlays | GPL-2.0 | Non |
| NVIDIA L4T BSP | Firmware, blobs GPU/BPMP, bibliothèques | Fourni via les images Switchroot (accord NVIDIA) | Propriétaire NVIDIA | Non |
| Linux mainline (Tegra) | Noyau alternatif pour Tegra X1 | https://git.kernel.org/ | GPL-2.0 | Non |
| Hyprland | Compositeur Wayland | https://github.com/hyprwm/Hyprland | BSD-3-Clause | Non (paquet Arch) |
| Waybar | Barre d'état | https://github.com/Alexays/Waybar | MIT | Non (paquet Arch) |
| Walker | Lanceur d'applications | https://github.com/abenz1267/walker | MIT | Non (paquet Arch) |
| uwsm | Gestion de session Wayland | https://github.com/Vladimir-csp/uwsm | MIT | Non (paquet Arch) |

## Détail par composant

### Omarchy 4.5.0 — MIT

Omarchy est une distribution Arch Linux avec Hyprland, publiée sous MIT
(confirmé dans le `README.md` du dépôt upstream). Le projet réutilise :

- les paquets `omarchy` et `omarchy-settings` pour `aarch64`, publiés sur
  `https://pkgs.omarchy.org/stable/aarch64/` (vérifié accessible le 2026-11-10,
  paquet `omarchy-4.5.0-3-aarch64.pkg.tar.zst`) ;
- les conventions de configuration (`~/.config/omarchy`, thèmes, `uwsm`) ;
- **pas** le noyau `linux-omarchy`, qui ne cible pas Tegra X1 ;
- **pas** l'ISO ARM64, qui embarque un chargeur et un noyau inadaptés à la
  Switch (voir [`docs/research/omarchy-4.5.0.md`](docs/research/omarchy-4.5.0.md)).

### hekate — GPL-2.0

Utilisé tel quel, sans modification : le projet ne fournit que des fichiers
`.ini` de configuration et un script qui copie les fichiers fournis par
l'utilisateur dans `bootloader/`. Toute redistribution d'un binaire hekate
devrait être accompagnée de la source correspondante (GPL-2.0).

### Switchroot — GPL-2.0 / BSD-3-Clause

Le projet **ne modifie pas** les binaires Switchroot. Le script
`scripts/integrate-switchroot.sh` copie des fichiers fournis par l'utilisateur,
vérifie leurs empreintes SHA-256 et refuse par défaut tout fichier non déclaré
dans `switchroot/manifest.toml`.

Conséquences licences :

- si vous redistribuez une image complète contenant le noyau ou U-Boot, vous
  devez fournir les sources correspondantes (GPL-2.0) ;
- les blobs NVIDIA (BPMP, GPU, firmware) ne sont pas couverts par la GPL et ne
  peuvent pas être redistribués librement : l'image produite localement reste
  à usage personnel, sauf accord NVIDIA.

### Arch Linux ARM

Les paquets conservent leur licence individuelle (`/usr/share/licenses/` dans
le rootfs). Le projet ne redistribue pas de paquets : il les installe depuis
les miroirs officiels.

### Polices et thèmes

Les polices Nerd Fonts (SIL OFL 1.1) et les thèmes Omarchy (MIT) sont installés
comme paquets ou récupérés depuis l'upstream ; aucune copie n'est versionnée
dans ce dépôt.

## Vérification

`./scripts/validate-architecture.sh` vérifie qu'aucun fichier de plus de 1 Mio,
qu'aucune bibliothèque partagée et qu'aucun exécutable ELF ne sont versionnés
dans le dépôt, afin qu'aucun blob non déclaré ne s'y glisse.
