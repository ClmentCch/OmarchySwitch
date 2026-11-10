# `bootloader/` — hekate et la chaîne de démarrage

hekate est le bootloader de première étape : injecté par RCM (ou chargé par un
modchip), il prépare les fichiers de démarrage et lance ATF puis U-Boot.

## Ce que contient ce dossier

| Fichier | Rôle |
|---|---|
| `hekate_ipl.ini` | Configuration principale (`sd:/bootloader/hekate_ipl.ini`) : section `[config]` + entrée OmarchySwitch |
| `configs/omarchyswitch-erista.ini` | Entrée à copier dans `sd:/bootloader/ini/` |
| `configs/omarchyswitch-erista-debug.ini` | Variante bring-up (log noyau dalle + USB) |
| `scripts/install-bootfiles.sh` | Copie les `.ini` et le bundle hekate officiel vers une partition FAT montée |

## Ce que ce dossier ne contient pas — volontairement

- **Le binaire hekate** (`hekate_ctcaer_*.bin`) : GPL-2.0, distribué par
  l'auteur. Téléchargez-le depuis <https://github.com/CTCaer/hekate/releases>
  (version épinglée : `v6.5.4`).
- **Le dossier `bootloader/sys/`** (`nyx.bin`, `res.pak`, `libsys_lp0.bso`,
  `libsys_minerva.bso`, `sys/l4t/bpmpfw*.bin`, `sys/l4t/mtc_tbl*.bin`) : fourni
  dans l'archive de release hekate. Sans ces fichiers, hekate refuse de
  démarrer L4T avec le message
  `missing lp0 (sleep) lib / missing minerva lib / update bootloader folder!`.
- **Les binaires Switchroot** (`bl31.bin`, `bl33.bin`, `uImage`, `initramfs`,
  `nx-plat.dtimg`, `boot.scr`) : voir [`../switchroot/README.md`](../switchroot/README.md).

## Ordre de démarrage réel

```text
RCM (fusée gelée, Erista uniquement)
  └─ hekate (payload)
       └─ L4T Loader : lit bootloader/ini/*.ini, prépare les fichiers
            └─ ATF (bl31.bin) : TrustZone / secure monitor
                 └─ U-Boot (bl33.bin) : exécute boot.scr
                      └─ uImage (noyau L4T 4.9.140) + nx-plat.dtimg + initramfs
                           └─ initramfs Switchroot : monte la partition ext4
                                └─ switch_root vers Arch Linux ARM
```

hekate **ne démarre pas** un `Image` + `.dtb` bruts : il passe par son L4T
Loader et par U-Boot. C'est la raison pour laquelle ce projet conserve la pile
Switchroot au lieu de fournir un noyau « PC » inadapté.

## Installer la configuration

### 1. Récupérer hekate

```bash
# Depuis https://github.com/CTCaer/hekate/releases (v6.5.4)
# Extraire l'archive : elle contient bootloader/ complet.
```

### 2. Préparer la partition FAT

```bash
# Partition FAT montée, par exemple /run/media/$USER/OMARCHYSW
./bootloader/scripts/install-bootfiles.sh \
    --target /run/media/$USER/OMARCHYSW \
    --hekate-zip ~/Downloads/hekate_ctcaer_6.5.4.zip
```

Le script :

1. vérifie que la cible ressemble à une partition de boot (dossier
   `bootloader/` ou racine vide) ;
2. copie le bundle hekate officiel **sans écraser** un `hekate_ipl.ini`
   existant sans confirmation ;
3. installe `hekate_ipl.ini` et les entrées de `configs/` ;
4. vérifie la présence de `bootloader/sys/l4t/` et signale les fichiers
   manquants.

### 3. Vérifier

```bash
find /run/media/$USER/OMARCHYSW/bootloader -maxdepth 2 -type f | sort
```

Attendu au minimum :

```text
bootloader/hekate_ipl.ini
bootloader/ini/omarchyswitch-erista.ini
bootloader/sys/l4t/bpmpfw.bin          (ou bpmpfw_b01.bin selon la révision)
bootloader/sys/l4t/mtc_tbl_config.bin
bootloader/sys/nyx.bin
bootloader/sys/res.pak
bootloader/sys/libsys_lp0.bso
bootloader/sys/libsys_minerva.bso
```

## Clés hekate utilisées et leur justification

| Clé | Valeur | Justification |
|---|---|---|
| `l4t=1` | — | Active le L4T Loader ; obligatoire pour Linux |
| `boot_prefixes` | `/switchroot/omarchyswitch/` | Répertoire des fichiers de boot sur la FAT |
| `id` | `OSWITCH` | Doit correspondre au label ext4 ; 7 caractères max |
| `rootdev` | `mmcblk0p2` | Repli si la recherche par label échoue (SD = `mmcblk0`) |
| `rootfstype` | `ext4` | Seul système de fichiers raisonnable sur Tegra (CPU/IO limités) |
| `rootlabel_retries` | `1` | Recherche par label : 1 tentative = 200 ms |
| `r2p_action` | `self` | « Reboot to payload » revient sur la même entrée |
| `fbconsole` | `9` | Pas de log noyau sur la dalle en usage normal |
| `uart_port` | `4` (debug) | Log série via USB, seule voie de diagnostic sur console retail |
| `earlycon` | `1` (debug) | Log avant l'init du pilote série |

Toutes ces clés proviennent de `README_CONFIG.txt` du bootstack Switchroot,
pas d'une supposition. Les clés Mariko (`dvfsb`, `gpu_dvfsc`,
`limit_gpu_clk`, `ram_oc*`) sont volontairement absentes.

## Dépannage

| Symptôme | Cause probable |
|---|---|
| « missing lp0 (sleep) lib / missing minerva lib » | `bootloader/sys/` incomplet : recopier le bundle hekate complet |
| Retour immédiat au menu hekate | fichier manquant dans `boot_prefixes` (souvent `bl31.bin` ou `bl33.bin`) ou `boot.scr` qui échoue |
| Écran noir, aucune activité | noyau absent/incompatible, ou modules non accordés au noyau |
| `failed to mount rootfs` | label ext4 ≠ `id=`, ou système de fichiers créé avec des options que le noyau 4.9 ne connaît pas |
| Boucle de démarrage Horizon OS | entrée par défaut modifiée : remettre `autoboot=0` et sélectionner l'entrée manuellement |

## Références

- hekate README : <https://github.com/CTCaer/hekate/blob/master/README.md>
- hekate releases : <https://github.com/CTCaer/hekate/releases>
- Switchroot — bootstack : <https://wiki.switchroot.org/wiki/linux/linux-bootstack-documentation>
