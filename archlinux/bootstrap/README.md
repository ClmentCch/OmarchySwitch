# `archlinux/bootstrap/` — préparation du rootfs aarch64

Le bootstrap réel est exécuté par `scripts/bootstrap-arch.sh` puis
`scripts/build-rootfs.sh`. Ce dossier documente les prérequis et les choix, pour
que la construction reste reproductible hors de ces scripts.

## Source

| Élément | Valeur |
|---|---|
| Tarball | `https://archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz` |
| Architecture | `aarch64` (ARMv8-A, Cortex-A57/A53 du Tegra X1) |
| Vérification | SHA-256 épinglé dans `configs/local.conf` + signature détachée `.sig` |
| Taille décompressée | ~1,1 Gio avant installation des paquets |

Le tarball « latest » est **régénéré** par Arch Linux ARM : son empreinte change.
C'est pourquoi le projet refuse de construire sans empreinte épinglée
(`--allow-unpinned-tarball` affiche l'empreinte observée pour la figer).

## Prérequis de l'hôte

| Outil | Usage | Paquet Arch | Paquet Debian/Ubuntu |
|---|---|---|---|
| `tar` | extraction | `tar` | `tar` |
| `curl` | téléchargement | `curl` | `curl` |
| `sha256sum` | vérification | `coreutils` | `coreutils` |
| `qemu-user-static` | exécution aarch64 sur x86_64 | `qemu-user-static-binfmt` | `qemu-user-static` |
| `binfmt_misc` | exécution transparente | noyau + systemd-binfmt | idem |
| `parted`, `mkfs.vfat`, `mkfs.ext4` | image | `parted dosfstools e2fsprogs` | idem |
| `rsync` (optionnel) | packaging | `rsync` | `rsync` |

Vérification :

```bash
./scripts/bootstrap-arch.sh --check-only
```

## Si l'hôte est x86_64

`chroot` a besoin d'exécuter des binaires aarch64. Deux conditions :

1. `qemu-aarch64-static` installé ;
2. handler `binfmt_misc` enregistré (`/proc/sys/fs/binfmt_misc/qemu-aarch64`).

```bash
# Debian/Ubuntu
sudo apt install qemu-user-static
sudo systemctl restart systemd-binfmt

# Arch
sudo pacman -S qemu-user-static-binfmt
sudo systemctl restart systemd-binfmt
```

Sans cela, `build-rootfs.sh` s'arrête avec un message explicite plutôt que de
produire un rootfs inutilisable.

## Ce que le bootstrap n'installe pas

- Aucun noyau : il vient de Switchroot.
- Aucun chargeur d'amorçage : hekate/U-Boot sont hors du rootfs.
- Aucun firmware : il vient du BSP Switchroot.
- Aucun paquet x86_64 : interdit par la validation.
