# `archlinux/packages/` — paquets Arch propres au projet

| Paquet | État | Rôle |
|---|---|---|
| `omarchyswitch-base` | prépa | Méta-paquet : dépendances de base, marqueur de distribution |
| `linux-switchroot` | **à tester** | Compilation du noyau L4T 4.9.140 depuis les sources Switchroot |

## Ce qui n'est pas packagé ici, et pourquoi

| Composant | Raison |
|---|---|
| `bl31.bin`, `bl33.bin`, `boot.scr`, `initramfs`, `uImage`, `nx-plat.dtimg` | Vivent sur la **partition FAT**, pas dans le rootfs ; un paquet Arch les installerait au mauvais endroit. Ils sont gérés par `switchroot/manifest.toml` + `scripts/integrate-switchroot.sh`. |
| Modules noyau et firmware | Proviennent du BSP Switchroot ; les empaqueter reviendrait à redistribuer des blobs NVIDIA. |
| Paquets Omarchy | Publiés par Omarchy pour `aarch64` sur `pkgs.omarchy.org` ; on les installe depuis ce dépôt, on ne les reconstruit pas. |

## Construire un paquet

```bash
cd archlinux/packages/omarchyswitch-base
makepkg -sri --needed
```

`makepkg` doit s'exécuter sur un hôte **aarch64** (ou dans un chroot aarch64).
Construire sur x86_64 produirait des binaires incompatibles — la validation du
dépôt et `osw_assert_no_foreign_elf` refusent ce cas.

## Conventions

- `arch=('aarch64')` (ou `('any')` pour un méta-paquet sans binaire).
- `license=('MIT')` pour le code du projet, licence upstream sinon.
- `pkgver` identique à `VERSION` pour les paquets du projet.
- Aucun `source=()` pointant vers un binaire non redistribuable.
- Toute construction non testée est marquée explicitement dans le `PKGBUILD`
  **et** dans `docs/05-status-matrix.md`.
