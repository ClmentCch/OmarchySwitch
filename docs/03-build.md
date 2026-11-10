# 03 — Construire

## Prérequis

| Élément | Détail |
|---|---|
| Hôte | Linux, `aarch64` natif ou `x86_64` avec qemu/binfmt |
| Root | nécessaire pour le rootfs, l'image et l'écriture disque |
| Réseau | Arch Linux ARM, Omarchy, (hekate pour la doc) |
| Espace | ~10 Gio libres pour rootfs + image |
| Outils | `tar`, `curl`, `parted`, `mkfs.vfat`, `mkfs.ext4`, `python3` ≥ 3.11 |

Vérification :

```bash
./scripts/bootstrap-arch.sh --check-only
```

## Étape 1 — Validation statique

```bash
./scripts/validate-architecture.sh
```

Ne nécessite ni root ni réseau. Détecte : fichiers manquants, scripts non
exécutables, erreurs de syntaxe shell, incohérences aarch64, manifests invalides,
secrets, liens Markdown cassés.

## Étape 2 — Bootstrap

```bash
./scripts/bootstrap-arch.sh --allow-unpinned-tarball
```

Télécharge le tarball Arch Linux ARM aarch64, affiche son SHA-256, et demande de
l'épingler dans `configs/local.conf` :

```bash
ALARM_TARBALL_SHA256="<empreinte observée>"
```

Ensuite, plus besoin de `--allow-unpinned-tarball`.

## Étape 3 — Rootfs

```bash
sudo ./scripts/build-rootfs.sh --output build/output/rootfs
```

Ce que fait le script :

1. extrait le tarball, vérifie que c'est bien de l'aarch64 ;
2. installe `archlinux/pacman/pacman.conf` et la mirrorlist ;
3. initialise le keyring (`pacman-key --init`, `--populate archlinuxarm`) ;
4. `pacman -Syu` puis installe `build/manifests/base-packages.txt` ;
5. applique l'overlay (hostname, os-release, fstab, unités) ;
6. crée l'utilisateur `switch` verrouillé ;
7. active `systemd-timesyncd` et `omarchyswitch-firstboot` ;
8. vérifie aarch64 et l'absence de binaires étrangers ;
9. écrit `/etc/omarchyswitch/build-info`.

Option `--stage-only` : extraction et pacman seulement, sans installation.

## Étape 4 — Composants Switchroot

Prérequis : avoir importé les fichiers (voir `switchroot/README.md`).

```bash
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted
sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs
```

Le script :

1. lit `switchroot/manifest.toml` (déclaration) et `manifest.local.toml`
   (empreintes mesurées) ;
2. vérifie chaque fichier par SHA-256 ;
3. refuse tout fichier non vérifié sauf `--allow-unverified` ;
4. construit `build/output/boot/` (partition FAT) ;
5. copie modules et firmware dans le rootfs ;
6. vérifie la cohérence noyau/modules/firmware ;
7. écrit `/etc/omarchyswitch/switchroot-provenance.txt`.

## Étape 5 — Omarchy

```bash
sudo ./scripts/integrate-omarchy.sh --rootfs build/output/rootfs
```

Ajoute le dépôt `pkgs.omarchy.org/stable/aarch64`, installe
`build/manifests/omarchy-packages.txt`, refuse `linux-omarchy`, applique les
surcharges de configuration.

## Étape 6 — Bureau

```bash
sudo ./scripts/install-desktop.sh --rootfs build/output/rootfs
```

Installe Hyprland/Waybar/foot/uwsm, active NetworkManager/BlueZ/seatd, configure
l'autologin tty1 + uwsm, installe les polices.

## Étape 7 — Image

```bash
sudo ./scripts/build-image.sh --rootfs build/output/rootfs \
     --output build/output/omarchyswitch-0.1.0.img --size 16G
```

Produit :

- GPT avec p1 FAT32 (`OMARCHYSW`) et p2 ext4 (`OSWITCH`) ;
- contenu de `build/output/boot/` sur p1 ;
- rootfs sur p2 ;
- `/etc/fstab` régénéré avec les labels ;
- fichier `.sha256` à côté de l'image.

## Étape 8 — Archive de release

```bash
./scripts/package-release.sh
```

Produit `dist/OmarchySwitch-Base-v0.1.0.zip`, vérifie l'intégrité, l'absence de
`local.conf`/`.git` et la présence des fichiers requis.

## Tout en une commande

```bash
./build/scripts/build-all.sh
```

Utile pour un build complet ; les étapes individuelles restent préférables pour
diagnostiquer un échec.

## Erreurs fréquentes

| Message | Cause | Solution |
|---|---|---|
| `binfmt_misc qemu-aarch64 is not registered` | hôte x86_64 sans qemu | installer `qemu-user-static`, redémarrer `systemd-binfmt` |
| `no SHA-256 pinned` | tarball non épinglé | première fois : `--allow-unpinned-tarball`, puis épingler |
| `SHA-256 mismatch` | tarball régénéré | re-télécharger avec `--force`, ré-épingler |
| `no component file(s) missing` | Switchroot non importé | `switchroot/README.md` |
| `refusing to copy them` | empreintes absentes | `import-components.sh` |
| `linux-omarchy was installed` | dépendance inattendue | retirer le paquet, corriger la liste |
| `refusing to build an image` | composant de boot absent | intégrer Switchroot, ou `--keep-going` pour une image de test |
