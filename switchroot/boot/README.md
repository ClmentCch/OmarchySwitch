# `switchroot/boot/` — étages de démarrage U-Boot / ATF / initramfs

**Contenu attendu :**

| Fichier | Rôle | Licence |
|---|---|---|
| `initramfs` | Trouve et monte la partition Linux, puis `switch_root` | GPL-2.0 |
| `boot.scr` | Script U-Boot : charge `uImage`, `nx-plat.dtimg`, `initramfs` | GPL-2.0 |
| `bl31.bin` | ARM Trusted Firmware (secure monitor, PSCI) | BSD-3-Clause |
| `bl33.bin` | U-Boot (étage chargé par hekate via le L4T Loader) | GPL-2.0-or-later |

## Détail du rôle de chacun

- **`bl31.bin`** : initialise TrustZone, fournit PSCI (allumage des cœurs,
  redémarrage). Sans lui, hekate signale `BL31 missing` et revient au menu.
- **`bl33.bin`** : U-Boot, qui lit `boot.scr` et charge le noyau. C'est lui qui
  interprète les clés de l'entrée `.ini` transmises par hekate.
- **`boot.scr`** : script compilé (`mkimage -T script`). Il définit les adresses
  de chargement, la ligne de commande noyau et lance `bootm`.
- **`initramfs`** : contient le script qui recherche la partition par label
  (`id=`), monte le rootfs, vérifie `/etc/switchroot_version.conf` puis exécute
  `switch_root`. Il refuse de basculer si le marqueur est absent.

## Origine

- Releases Switchroot (fichiers de démarrage de la distribution).
- Sources :
  - U-Boot : <https://gitlab.com/switchroot/bootstack/switch-uboot> (`linux-hekatf`)
  - scripts U-Boot : <https://gitlab.com/switchroot/bootstack/switch-uboot-scripts>
  - ATF : <https://gitlab.com/switchroot/bootstack/switch-atf> (`switch-v4-atf2.6`)
  - initramfs : <https://gitlab.com/switchroot/kernel/l4t-initramfs>

## Mise en place

```bash
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted
```

Le script copie ces quatre fichiers tels quels : aucun n'est modifié par
OmarchySwitch. En particulier, `boot.scr` reste celui de Switchroot pour la
phase 0.1.0 ; un script personnalisé (par exemple pour changer la ligne de
commande noyau) sera ajouté dans une version ultérieure, une fois un démarrage
réel observé.

## Vérification

```bash
# bl31/bl33 : doivent être des binaires ARM64, pas du texte
file switchroot/boot/bl31.bin switchroot/boot/bl33.bin

# boot.scr : en-tête U-Boot "legacy image"
file switchroot/boot/boot.scr

# initramfs : archive compressée (gzip/xz/zstd) ou cpio
file switchroot/boot/initramfs
```

## Pièges

- Un `boot.scr` compilé pour une autre adresse de chargement provoque un retour
  immédiat au menu hekate.
- Un `initramfs` incompatible avec le noyau produit un écran noir : c'est le
  premier suspect si le noyau démarre mais que le rootfs n'est jamais monté.
- Ne pas renommer ces fichiers : `boot.scr` et `uImage` sont des noms attendus
  par le script U-Boot ; `initramfs` et `nx-plat.dtimg` sont attendus par
  l'initramfs.
