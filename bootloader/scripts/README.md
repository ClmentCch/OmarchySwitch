# `bootloader/scripts/`

## `install-bootfiles.sh`

Installe la configuration OmarchySwitch sur une partition FAT montée.

```bash
./bootloader/scripts/install-bootfiles.sh \
    --target /run/media/$USER/OMARCHYSW \
    --hekate-zip ~/Downloads/hekate_ctcaer_6.5.4.zip
```

Ce qu'il fait :

1. vérifie que la cible ressemble à une partition de boot ;
2. fusionne le bundle hekate officiel (`bootloader/`) sans écraser la
   configuration existante sans confirmation ;
3. installe `hekate_ipl.ini` (sauvegarde `.bak` si un autre fichier existe) ;
4. installe `bootloader/ini/omarchyswitch-*.ini` ;
5. vérifie `bootloader/sys/` et `bootloader/sys/l4t/` ;
6. signale le préfixe de boot manquant.

Options : `--hekate-dir` (dossier déjà extrait), `--force` (écrase sans
demander).

Codes de sortie : `0` succès, `1` fichiers runtime manquants, `2` usage.

## Ce que ce script ne fait pas

- Il ne télécharge pas hekate (GPL, release officielle uniquement).
- Il ne copie pas les fichiers Switchroot (voir `switchroot/`).
- Il ne modifie jamais la partition eMMC.
