# `switchroot/kernel/` — noyau L4T

**Contenu attendu :** `uImage`, le noyau Linux 4.9.140 du BSP NVIDIA L4T, tel
que fourni par Switchroot.

## Pourquoi ce noyau et pas un autre

| Candidat | Écran | Wi-Fi/BT | Audio | GPU | systemd |
|---|---|---|---|---|---|
| L4T 4.9.140 (Switchroot) | oui (pilote DSI NVIDIA) | oui (`brcmfmac` + firmware BSP) | oui | oui (blobs NVIDIA) | **non** (noyau trop ancien) |
| `linux-omarchy` aarch64 | non (pas de pilote Tegra X1) | non | non | non | oui |
| mainline 7.x + patchs Switchroot | partiel (bring-up nécessaire) | expérimental | expérimental | limité (nouveau) | oui |

C'est pourquoi le projet conserve le noyau L4T comme base fonctionnelle et
isole le problème systemd dans une ADR.

## Origine du fichier

- Release Switchroot (Ubuntu Bionic 5.1.2 / Jammy) : le `uImage` se trouve dans
  les fichiers de démarrage de la distribution, et dans le rootfs sous
  `/boot/switchroot/`.
- Compilation : <https://gitlab.com/switchroot/kernel/l4t-kernel-4.9>
  (tag de référence `linux-5.1.0_r2`, branche `lineage-19.1`), avec les dépôts
  `l4t-soc-t210`, `l4t-platform-t210-common`, `l4t-platform-t210-switch`,
  `l4t-kernel-nvgpu`. Le `PKGBUILD` correspondant est
  [`../../archlinux/packages/linux-switchroot/PKGBUILD`](../../archlinux/packages/linux-switchroot/PKGBUILD)
  (non testé).

## Contraintes vérifiées

- **Format** : U-Boot `uImage` (en-tête 64 octets, nom `Linux` à l'offset 32,
  adresse de chargement `0x80200000`), pas un `Image` brut ni un `vmlinux`.
- **Correspondance modules** : le noyau et `/usr/lib/modules` doivent provenir de
  la même build. `integrate-switchroot.sh` vérifie la présence du répertoire
  attendu (`4.9.140*`) et avertit sinon.
- **Initramfs** : celui de Switchroot, pas celui de `mkinitcpio`. Le noyau
  cherche `initramfs` dans `boot_prefixes`.
- **Licence** : GPL-2.0. Si vous distribuez une image, vous devez fournir les
  sources correspondantes.

## Mise en place

```bash
# Depuis une release Switchroot déjà extraite
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted
```

Puis vérifier :

```bash
./switchroot/scripts/import-components.sh --list-missing
file switchroot/kernel/uImage            # "u-boot legacy uImage, ... ARM"
```
