# `installer/scripts/`

## `install.sh`

Orchestrateur d'installation sur carte SD, à lancer depuis une machine Linux
**aarch64** (ou x86_64 avec `qemu-user-static` et `binfmt_misc`).

```bash
# Vérification seule, aucun accès disque
sudo ./installer/scripts/install.sh --device /dev/sdX --dry-run

# Installation complète sur une carte (destructive)
sudo ./installer/scripts/install.sh --device /dev/sdX --yes
```

Étapes :

1. contrôles de sûreté : périphérique bloc, taille, non monté, pas de partition
   système, confirmation explicite ;
2. `partition-sd.sh` : GPT, FAT32 de boot, ext4 racine compatible noyau 4.9 ;
3. montage, `pacstrap`, `integrate-switchroot.sh`, `build-image` non utilisé ici ;
4. `install-bootfiles.sh` sur la partition de boot ;
5. résumé et vérifications finales.

## Ce que ce script refuse

| Situation | Réaction |
|---|---|
| Périphérique qui n'est pas un disque (partition) | refus |
| Périphérique monté | refus |
| Partition contenant `/`, `/boot`, `/home` | refus |
| Disque interne (`/dev/nvme0n1`, `/dev/sda` système) | avertissement + confirmation |
| Absence de `--device` | refus |
| Absence de `--yes` | demande interactive |

## Limites assumées

- **Non testé sur matériel réel.** Aucune carte n'a été écrite par ce script
  dans l'environnement de développement.
- Il formate : toute donnée présente sur la carte est perdue.
- Il ne crée pas de sauvegarde de la carte existante.
- Il ne détecte pas une carte contrefaite (capacité annoncée fausse).

## Prérequis

`sgdisk`, `mkfs.vfat`, `mkfs.ext4`, `mount`, `rsync`, `pacstrap` (ou le tarball
bootstrap), `partprobe` recommandé.
