# Restauration des fichiers de démarrage

## Quand l'utiliser

- vous avez modifié `hekate_ipl.ini` et la console ne démarre plus l'entrée Linux ;
- une entrée `.ini` a été corrompue par un éditeur (fins de ligne CRLF, `;` mal placé) ;
- vous voulez revenir à la configuration livrée par OmarchySwitch.

## Ce que fait `restore-bootfiles.sh`

1. sauvegarde les `.ini` actuels (`*.bak-<horodatage>`) ;
2. réinstalle `hekate_ipl.ini` et les entrées de `bootloader/configs/` ;
3. vérifie la syntaxe des fichiers installés ;
4. vérifie la présence des fichiers de boot (`uImage`, `bl31.bin`, ...) ;
5. affiche un résumé.

Il **ne touche pas** au rootfs, aux binaires Switchroot ni à Horizon OS.

## Usage

```bash
# Partition FAT montée
./recovery/restore/restore-bootfiles.sh --target /run/media/$USER/OMARCHYSW

# Simulation
./recovery/restore/restore-bootfiles.sh --target /run/media/$USER/OMARCHYSW --dry-run
```

## Si cela ne suffit pas

| Problème | Action |
|---|---|
| `bootloader/sys/` incomplet | recopier le bundle hekate officiel (voir `bootloader/README.md`) |
| fichier de boot manquant | réimporter les composants Switchroot (`switchroot/scripts/import-components.sh`) |
| rootfs illisible | `fsck.ext4 -f`, puis reconstruire |
| Horizon OS ne démarre plus | restaurer la sauvegarde eMMC faite avant toute manipulation (hors périmètre de ce projet) |

## Ce que ce script ne peut pas faire

Il ne restaure pas ce qui n'a jamais été versionné : noyau, DTB, modules,
firmware, ATF, U-Boot. Ces fichiers doivent provenir de vos sauvegardes ou des
sources Switchroot.
