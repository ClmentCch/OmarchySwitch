# Partitionnement

## Disposition utilisée par le projet

```text
GPT
├─ p1  FAT32  1 GiB    LABEL=OMARCHYSW   bootloader/, switchroot/omarchyswitch/
└─ p2  ext4   reste    LABEL=OSWITCH     rootfs Arch Linux ARM
```

| Contrainte | Raison |
|---|---|
| GPT (pas MBR) | hekate et U-Boot lisent les tables GPT |
| p1 en FAT32 | hekate ne lit pas ext4 pour les fichiers de boot |
| Label ≤ 7 caractères pour la racine | limite de la clé `id=` de hekate (`OSWITCH`) |
| ext4 sans `orphan_file` ni `metadata_csum_seed` | noyau L4T 4.9 trop ancien |
| Aucune partition supplémentaire | évite les ambiguïtés de numérotation attendues par `rootdev=mmcblk0p2` |

## Deux scripts, deux usages

| Script | Usage |
|---|---|
| `scripts/build-image.sh` | **Recommandé** : crée l'image complète (partitions + systèmes de fichiers + contenu) |
| `installer/partition/partition-sd.sh` | Avancé : partitionne et formate une carte, sans copier de contenu |

`partition-sd.sh` existe pour les cas où l'on veut préparer la carte puis copier
les fichiers soi-même (par exemple pour ajuster la taille de la partition de
boot). Il détruit les données de la carte.

## Vérifier le résultat

```bash
lsblk -o NAME,SIZE,LABEL,FSTYPE,PARTTYPENAME /dev/sdX
sudo tune2fs -l /dev/sdX2 | grep -E 'Filesystem features|Filesystem label'
```

La ligne `Filesystem features` ne doit contenir ni `orphan_file` ni
`metadata_csum_seed`.
