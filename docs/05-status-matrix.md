# 05 — Matrice d'état

> État réel au 2026-11-10. **Aucune fonctionnalité n'a été testée sur une
> console réelle.** « préparé » signifie : fichiers, scripts et documentation
> écrits, exécutés seulement dans un environnement de développement sans
> matériel Switch.

## Vue d'ensemble

| Fonctionnalité | État | Explication |
|---|---|---|
| Arborescence et documentation | **terminé** | Créées et vérifiées par la validation du dépôt |
| Configuration hekate (modèles) | **terminé** | Fichiers écrits, syntaxe vérifiée ; non testés sur console |
| Bootstrap Arch Linux ARM64 | **terminé** | Script complet ; l'extraction/pacman n'a pas été exécutée ici (pas de rootfs réel construit) |
| Overlay rootfs (hostname, fstab, os-release, unités) | **terminé** | Fichiers présents et cohérents |
| Validation statique (CI) | **terminé** | `scripts/validate-architecture.sh` + workflow |
| Packaging de l'archive | **terminé** | ZIP construit et vérifié |
| Intégration Switchroot (mécanisme) | **préparé** | Vérification par empreinte, refus par défaut ; aucun binaire fourni |
| Noyau L4T | **bloqué** | À fournir par l'utilisateur depuis Switchroot |
| DTB `nx-plat.dtimg` | **bloqué** | À fournir depuis Switchroot |
| Modules noyau | **bloqué** | À fournir depuis l'image Switchroot |
| Firmware (Wi-Fi/BT/GPU) | **bloqué** | À fournir depuis le BSP ; non redistribuable |
| ATF / U-Boot / boot.scr / initramfs | **bloqué** | À fournir depuis Switchroot |
| Démarrage de la chaîne hekate → initramfs | **à tester** | Théoriquement prêt, jamais exécuté |
| systemd sur noyau 4.9 | **bloqué** | Incompatibilité de version (ADR 0004) |
| Session graphique Hyprland | **bloqué** | Dépend de systemd + pilote GPU BSP |
| Waybar / Walker / foot | **préparé** | Paquets listés, configurations écrites |
| Wi-Fi | **à tester** | Dépend firmware + DTB + NetworkManager (bloqué par systemd) |
| Bluetooth | **à tester** | Dépend firmware `.hcd` + BlueZ |
| Audio | **à tester** | Dépend modules `snd_soc_tegra210_*` + PipeWire |
| Joy-Con | **à tester** | Dépend driver HID + pairing dump |
| Tactile | **à tester** | Dépend `stmfts` + rotation configurée |
| Batterie / charge | **à tester** | Dépend MAX17050/BQ24193 + DTB |
| Veille (LP0) | **à tester** | Dépend `libsys_lp0.bso` + noyau |
| Dock / HDMI | **à tester** | Aucune validation CEC/USB3 |
| Portage d'applications Switchroot | **bloqué** | Analyse faite, aucun paquet construit |
| Installation sur eMMC | **non supporté** | Hors périmètre, risque pour Horizon OS |
| Mariko (2019/Lite/OLED) | **non supporté** | Matériel différent |

## Détail par couche

### Amorçage

| Élément | Fichier | État |
|---|---|---|
| `hekate_ipl.ini` | `bootloader/hekate_ipl.ini` | terminé (modèle) |
| Entrée normale | `bootloader/configs/omarchyswitch-erista.ini` | terminé (modèle) |
| Entrée debug | `bootloader/configs/omarchyswitch-erista-debug.ini` | terminé (modèle) |
| Installation vers la FAT | `bootloader/scripts/install-bootfiles.sh` | préparé |
| Manifeste de composants | `switchroot/manifest.toml` | terminé |
| Import + empreintes | `switchroot/scripts/import-components.sh` | préparé |
| Intégration | `scripts/integrate-switchroot.sh` | préparé |

### Système

| Élément | Fichier | État |
|---|---|---|
| `pacman.conf` aarch64 | `archlinux/pacman/pacman.conf` | terminé |
| Mirrorlist | `archlinux/pacman/mirrorlist` | terminé |
| Rootfs | `scripts/build-rootfs.sh` | préparé (non exécuté ici) |
| Overlay `/etc` | `archlinux/rootfs/overlay/` | terminé |
| Premier démarrage | `archlinux/rootfs/firstboot/` | préparé |
| Méta-paquet | `archlinux/packages/omarchyswitch-base/` | préparé |
| Paquet noyau | `archlinux/packages/linux-switchroot/` | **à tester** (non construit) |

### Bureau

| Élément | Fichier | État |
|---|---|---|
| Surcharge Hyprland | `omarchy/configs/hypr/omarchyswitch.conf` | préparé |
| Environnement de session | `omarchy/configs/environment.d/` | terminé |
| Waybar (référence) | `desktop/waybar/config.switch.jsonc` | préparé |
| Polices | `desktop/fonts/packages.txt` | terminé |
| Session uwsm + autologin | `scripts/install-desktop.sh` | préparé |
| Thèmes | `desktop/themes/README.md` | documenté |

## Ce que « terminé » ne veut pas dire

Un fichier marqué **terminé** est écrit, cohérent et validé statiquement. Cela ne
signifie pas qu'il produit un système qui démarre : la validation ne remplace pas
un test matériel. La seule ligne qui parle de démarrage est explicitement
**à tester**.
