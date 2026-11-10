# `archlinux/pacman/`

| Fichier | Destination dans le rootfs |
|---|---|
| `pacman.conf` | `/etc/pacman.conf` |
| `mirrorlist` | `/etc/pacman.d/mirrorlist` |

## Décisions

- `Architecture = aarch64` en dur : le projet ne construit que pour ARM64. Un
  `Architecture = auto` pourrait installer des paquets de l'hôte lors d'un
  `pacman --root` exécuté sur x86_64 — exactement ce qu'il faut éviter.
- `$arch`/`$repo` dans les URL : c'est la convention Arch Linux ARM, et cela
  évite de dupliquer les miroirs pour chaque dépôt.
- Repos `core`, `extra`, `alarm`, `aur` : `alarm` et `aur` sont spécifiques à
  Arch Linux ARM.
- Le dépôt `[omarchy]` n'est **pas** ici : il est ajouté par
  `scripts/integrate-omarchy.sh`, car le canal (stable/edge) est un choix de
  build.
- `ParallelDownloads = 4` : raisonnable sur une carte SD et un réseau domestique.

## Miroirs

`mirrorlist` ne contient que des miroirs Arch Linux ARM. Les miroirs Arch
x86_64 sont volontairement absents : ils serviraient des paquets incompatibles.

## Vérification

```bash
grep -n 'Architecture' archlinux/pacman/pacman.conf     # doit afficher aarch64
grep -c '^Server' archlinux/pacman/mirrorlist
```

`scripts/validate-architecture.sh` vérifie `Architecture = aarch64` et la
présence des sections `[core]` et `[alarm]`.
