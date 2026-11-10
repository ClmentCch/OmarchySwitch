# Stockage — microSD et eMMC

## Cible de la base 0.1.0

**microSD uniquement.** L'eMMC interne contient Horizon OS ; une erreur de
partitionnement la rend inutilisable. `emmc=1` n'est volontairement pas utilisé
dans les entrées hekate du projet.

## Disposition des partitions

```text
p1  FAT32  LABEL=OMARCHYSW   bootloader/, switchroot/omarchyswitch/
p2  ext4   LABEL=OSWITCH     rootfs Arch Linux ARM
```

Le schéma GPT est créé par `scripts/build-image.sh`. Les labels sont la seule
adresse utilisée : `mmcblk0` (SD) et `mmcblk1` (eMMC) peuvent permuter selon le
contexte de démarrage.

## Contrainte majeure : options ext4

Le noyau L4T 4.9.140 ne connaît pas les fonctionnalités ext4 récentes. Créer le
système de fichiers avec les options par défaut d'e2fsprogs récentes produit un
`failed to mount rootfs` au démarrage, sans message explicite.

`build-image.sh` utilise donc :

```bash
mkfs.ext4 -O ^orphan_file,^metadata_csum_seed -L OSWITCH <partition>
```

Pour corriger une carte existante :

```bash
sudo tune2fs -O ^orphan_file,^metadata_csum_seed /dev/sdX2
```

## Tailles

| Élément | Valeur par défaut | Remarque |
|---|---|---|
| `BOOT_PART_SIZE` | 1024 MiB | FAT32 ; contient noyau, initramfs, DTB, boot.scr, hekate |
| `ROOT_PART_SIZE` | 12 GiB | rootfs Arch + Omarchy + navigateur |
| `IMAGE_SIZE` | 16 G | taille du fichier image (pas de la carte réelle) |

Sur une carte réelle, la partition racine occupe le reste de la carte ;
`omarchyswitch-firstboot` exécute `resize2fs` au premier démarrage.

## Performances et durabilité

La SD est lente et s'use. Recommandations :

- `noatime` sur `/` et `/boot` (déjà dans `fstab`) ;
- `tmpfs` sur `/tmp` (déjà proposé) ;
- éviter les écritures de journal agressives (journald en `Storage=volatile`
  est un choix raisonnable sur carte SD, à décider par l'utilisateur) ;
- préférer une carte A2/U3 de bonne qualité.

## Vérification

```bash
lsblk -o NAME,SIZE,LABEL,FSTYPE
sudo fsck.ext4 -fn /dev/sdX2
```

## Rien n'est testé

Aucune image produite par ce dépôt n'a été écrite sur une carte puis démarrée.
