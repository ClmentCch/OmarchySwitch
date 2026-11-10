# `archlinux/` — Arch Linux ARM64 pour Erista

Cette couche fournit le système utilisateur : rootfs aarch64, configuration
pacman, overlay de configuration, paquets Arch propres au projet.

## Contenu

| Chemin | Rôle |
|---|---|
| `bootstrap/` | Profil de bootstrap et prérequis du tarball Arch Linux ARM |
| `pacman/pacman.conf` | Dépôts aarch64 (`core`, `extra`, `alarm`, `aur`), `Architecture = aarch64` |
| `pacman/mirrorlist` | Miroirs Arch Linux ARM |
| `rootfs/overlay/` | Fichiers copiés tels quels dans le rootfs (`/etc/hostname`, `os-release`, `fstab`, unité systemd) |
| `rootfs/firstboot/` | Script exécuté au premier démarrage (`omarchyswitch-firstboot`) |
| `packages/` | `PKGBUILD` Arch : méta-paquet et noyau Switchroot (les fichiers de boot vivent sur la partition FAT, pas dans un paquet) |

## Principe directeur

Le rootfs est construit **à partir du tarball officiel Arch Linux ARM aarch64**
(<https://archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz>), puis :

1. `pacman` est pointé vers les miroirs ARM (`mirror.archlinuxarm.org`) ;
2. les paquets de base sont installés depuis les dépôts Arch ARM ;
3. l'overlay OmarchySwitch configure le système ;
4. les composants Switchroot sont ajoutés par `scripts/integrate-switchroot.sh` ;
5. Omarchy est ajouté par `scripts/integrate-omarchy.sh`.

Aucun paquet Ubuntu, aucun `.deb`, aucun paquet `x86_64` n'intervient.
`scripts/validate-architecture.sh` et `osw_assert_no_foreign_elf` le vérifient.

## Point bloquant documenté

Arch Linux ARM embarque systemd 261, qui ne peut pas démarrer sur le noyau
L4T 4.9.140 (exige ≥ 4.15, cgroup v2). Voir
[`../docs/06-known-limitations.md`](../docs/06-known-limitations.md) et
[`../docs/adr/0004-systemd-kernel-compatibility.md`](../docs/adr/0004-systemd-kernel-compatibility.md).

## Vérifications

```bash
./scripts/validate-architecture.sh
grep -n 'Architecture' archlinux/pacman/pacman.conf
```
