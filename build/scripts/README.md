# `build/scripts/`

## `build-all.sh`

Enchaîne la chaîne complète de construction.

```bash
sudo ./build/scripts/build-all.sh --arch-root /srv/archarm
sudo ./build/scripts/build-all.sh --arch-root /srv/archarm --with-omarchy --image
```

| Étape | Script appelé | Sortie |
|---|---|---|
| 1 | `bootstrap-arch.sh` | `build/src/ArchLinuxARM-aarch64-latest.tar.gz` |
| 2 | `build-rootfs.sh` | `build/output/rootfs` |
| 3 | `integrate-switchroot.sh` | rootfs + `build/output/boot` |
| 4 (option) | `integrate-omarchy.sh` | paquets Omarchy dans le rootfs |
| 5 (option) | `install-desktop.sh` | configurations bureau |
| 6 (option) | `build-image.sh` | `build/output/omarchyswitch-<version>-erista.img` |

Options : `--with-omarchy`, `--image`, `--force`, `--yes`, `--arch-root DIR`
(`pacstrap` a besoin d'une installation Arch ARM pour installer des paquets
aarch64 ; sur un hôte x86_64, `qemu-user-static` et `binfmt_misc` sont requis).

## `fetch-upstreams.sh`

Récupère les **sources** des projets amont (pas les binaires) pour consultation
et comparaison de licences.

```bash
./build/scripts/fetch-upstreams.sh --dest build/upstream
```

Clône de façon superficielle : Omarchy, hekate, le noyau L4T, l'initramfs, les
overlays DTB, ATF, U-Boot, les scripts U-Boot. Affiche la licence détectée de
chaque dépôt.

**Aucun fichier récupéré n'est copié dans le dépôt** : `build/upstream/` est
ignoré par Git.

## Codes de sortie

- `build-all.sh` : `0` succès, `1` étape échouée (s'arrête à la première erreur
  sauf `--keep-going`), `2` usage.
- `fetch-upstreams.sh` : `0` succès, `1` au moins un clone a échoué.

## Avertissement

`build-all.sh` ne prétend pas produire une image démarrable : les composants
matériels doivent être importés au préalable, et systemd reste incompatible avec
le noyau 4.9 (voir `docs/adr/0004-systemd-kernel-compatibility.md`).
