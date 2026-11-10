# 08 — Packaging Arch

## Ce qui est packagé

| Paquet | Emplacement | État |
|---|---|---|
| `omarchyswitch-base` | `archlinux/packages/omarchyswitch-base/` | prépa (méta-paquet, `arch=any`) |
| `linux-switchroot` | `archlinux/packages/linux-switchroot/` | **non testé** (compilation du noyau) |

## Ce qui n'est pas packagé, et pourquoi

| Élément | Raison | Où c'est géré |
|---|---|---|
| `uImage`, `bl33.bin`, `bl31.bin`, `boot.scr`, `initramfs`, `nx-plat.dtimg` | Vivent sur la partition FAT, pas dans le rootfs | `switchroot/manifest.toml`, `scripts/integrate-switchroot.sh` |
| Modules noyau et firmware | Blobs BSP / licence NVIDIA | `switchroot/modules`, `switchroot/firmware` |
| Paquets Omarchy | Publiés par Omarchy pour aarch64 | `scripts/integrate-omarchy.sh` |
| Hyprland, Waybar, Walker | Paquets Arch officiels / AUR | `build/manifests/desktop-packages.txt` |

Un paquet Arch qui installerait des fichiers de boot dans `/boot` du rootfs
serait une erreur de conception : hekate lit la **partition FAT**, pas `/boot`.

## Conventions du projet

```bash
pkgname=...
pkgver=$(cat ../../../VERSION)   # ou version upstream pour un composant tiers
pkgrel=1
arch=('aarch64')                 # ou ('any') pour un paquet sans binaire
license=('MIT')                  # licence réelle du contenu
```

Règles :

1. `sha256sums` renseigné pour tout paquet publiable — `SKIP` uniquement pendant
   le développement, avec un commentaire `TODO`.
2. Aucun binaire propriétaire dans `source=()`.
3. `depends`/`makedepends` explicitement listés, pas de dépendance implicite à
   l'hôte.
4. `package()` n'écrit que sous `$pkgdir`.
5. Toute construction non testée est marquée `UNTESTED` dans l'en-tête et dans
   `docs/05-status-matrix.md`.

## Construire

```bash
# Sur un hôte aarch64 (ou dans un chroot aarch64)
cd archlinux/packages/omarchyswitch-base
makepkg -sri --needed
```

Sur x86_64, `makepkg` produirait des binaires incompatibles : la validation du
dépôt et `osw_assert_no_foreign_elf` le détecteraient.

## Méta-paquet : à quoi il sert

`omarchyswitch-base` ne contient aucun binaire. Il déclare les dépendances
communes pour qu'un rootfs reconstruit puisse être comparé à une liste unique,
et il affiche un message rappelant que le noyau et les fichiers de boot ne sont
pas inclus.

## Paquet noyau : pourquoi il est marqué non testé

`linux-switchroot` compile le noyau L4T depuis GitLab. Trois raisons de ne pas le
présenter comme fonctionnel :

1. l'arbre L4T attend un environnement de build NVIDIA (toolchain, scripts) ;
2. les device trees viennent d'un autre dépôt ;
3. la compilation n'a pas été exécutée dans cet environnement.

Le `PKGBUILD` documente la démarche et échoue explicitement si `nx-plat.dtimg`
n'est pas fourni, plutôt que de produire un noyau sans device tree.
