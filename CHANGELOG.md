# Changelog

Toutes les modifications notables du projet OmarchySwitch sont consignées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le
projet utilise le [versionnage sémantique](https://semver.org/lang/fr/).

## [0.1.0] - 2026-11-10

Première base technique du projet. **Pre-release : rien n'est installable ni testé sur console.**

### Ajouté

- Arborescence complète du projet (`bootloader/`, `switchroot/`, `archlinux/`,
  `hardware/`, `omarchy/`, `desktop/`, `applications/`, `installer/`,
  `recovery/`, `build/`, `configs/`, `scripts/`, `docs/`).
- Documentation d'architecture et de chaîne de démarrage, avec ADR pour les
  décisions structurantes (Arch ARM comme base, chaîne hekate/L4T, absence de
  binaires versionnés, compatibilité systemd/noyau).
- Configuration hekate : `hekate_ipl.ini` modèle, entrées L4T
  (`l4t=1`, `boot_prefixes=/switchroot/omarchyswitch/`) pour Erista, variante
  avec journalisation série/USB, script d'installation vers la partition FAT.
- Manifeste de provenance Switchroot (`switchroot/manifest.toml`) avec
  emplacements, licences et empreintes à compléter, plus un script
  d'intégration qui refuse par défaut les fichiers non vérifiés.
- Bootstrap Arch Linux ARM64 : `pacman.conf` aarch64, mirrorlist, profil de
  bootstrap, overlay rootfs (hostname, os-release, `switchroot_version.conf`,
  fstab modèle, unité de first boot).
- Squelettes de paquets Arch : `omarchyswitch-base`, `linux-switchroot`,
  `switchroot-bootfiles`.
- Adaptations Omarchy 4.5.0 : tag upstream épinglé, configurations Hyprland /
  Waybar / uwsm / `environment.d` pour écran 720p tactile, script d'application
  idempotent avec `--dry-run`.
- Documentation matérielle Tegra X1 par sous-système (GPU, audio, Joy-Con,
  Wi-Fi, Bluetooth, tactile, stockage, énergie) avec état réel et prérequis.
- Guide de portage des applications Switchroot vers Arch ARM64 et manifeste
  d'applications.
- Installateur hôte : partitionnement GPT (FAT32 + ext4), first boot,
  diagnostics et restauration des fichiers de démarrage.
- Outillage : `bootstrap-arch.sh`, `build-rootfs.sh`, `integrate-switchroot.sh`,
  `integrate-omarchy.sh`, `install-desktop.sh`, `validate-architecture.sh`,
  `build-image.sh`, `package-release.sh`, plus une bibliothèque commune.
- CI GitHub Actions : validation statique, packaging de l'archive, job manuel
  de bootstrap ARM64.
- `validate-architecture.sh` : contrôle des fichiers requis, des bits
  exécutables, de la syntaxe shell, des configurations ini, de la cohérence
  aarch64, de l'absence de binaires x86_64 et de secrets.

### Limites connues à cette version

- Aucun binaire matériel (noyau, DTB, modules, firmware, ATF, U-Boot) n'est
  inclus ; l'intégration échoue volontairement tant que ces fichiers et leurs
  empreintes ne sont pas fournis.
- systemd 261 d'Arch Linux ARM ne démarre pas sur le noyau L4T 4.9.140 de
  Switchroot ; aucune solution n'est encore validée (voir ADR 0004).
- Aucun test sur console réelle.
