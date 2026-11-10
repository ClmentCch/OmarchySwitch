# 02 — Chaîne de démarrage

## Vue d'ensemble

```text
1. RCM (fusée gelée)                injection du payload, Erista uniquement
2. hekate                           menu, L4T Loader, préparation des fichiers
3. ATF (bl31.bin)                   secure monitor, PSCI, lance U-Boot
4. U-Boot (bl33.bin)                exécute boot.scr
5. boot.scr                         charge noyau, DTB, initramfs
6. uImage (Linux 4.9.140-l4t)       démarre, monte l'initramfs
7. initramfs Switchroot             trouve la partition par label, switch_root
8. rootfs Arch Linux ARM            /sbin/init (systemd) → BLOQUÉ (voir ADR 0004)
```

## Détail par étape

### 1. RCM

Erista est vulnérable à CVE-2018-6242 : maintenir **VOL+** et appuyer sur
**Power** met le SoC en mode RCM, qui accepte un payload arbitraire par USB.

- Nécessite un injecteur (PC, dongle, téléphone).
- N'existe pas sur Mariko (hors périmètre).
- hekate est le payload utilisé.

### 2. hekate et son L4T Loader

hekate lit `sd:/bootloader/hekate_ipl.ini` et les fichiers de
`sd:/bootloader/ini/`. Pour une entrée `l4t=1` :

1. il résout `boot_prefixes` (ici `/switchroot/omarchyswitch/`) ;
2. il charge `bl31.bin`, `bl33.bin`, les tables RAM et le firmware BPMP depuis
   `bootloader/sys/l4t/` ;
3. il transmet les clés de l'entrée `.ini` à U-Boot ;
4. il lance ATF.

**Fichiers exigés côté hekate :**

```text
bootloader/sys/libsys_lp0.bso        (veille)
bootloader/sys/libsys_minerva.bso    (training DRAM)
bootloader/sys/nyx.bin, res.pak      (interface)
bootloader/sys/l4t/bpmpfw*.bin       (firmware BPMP)
bootloader/sys/l4t/mtc_tbl*.bin      (tables mémoire)
```

Sans eux : `missing lp0 (sleep) lib / missing minerva lib / update bootloader
folder!` et retour au menu.

### 3. ATF — `bl31.bin`

Implémente le secure monitor, PSCI (démarrage des cœurs, reset) et lance
U-Boot. Absent : `BL31 missing`.

### 4. U-Boot — `bl33.bin`

Charge le noyau et le DTB, applique la ligne de commande, exécute `boot.scr`.
C'est lui qui interprète les clés transmises par hekate (`rootdev`, `id`,
`fbconsole`, `uart_port`, ...).

### 5. `boot.scr`

Script compilé (`mkimage -T script`). Il définit :

- l'adresse de chargement du noyau (`0x80200000` pour uImage) ;
- le fichier DTB (`nx-plat.dtimg`) ;
- l'initramfs ;
- la ligne de commande noyau.

Un `boot.scr` inadapté provoque un retour immédiat au menu hekate.

### 6. Noyau — `uImage`

Linux 4.9.140 du BSP NVIDIA, patché par Switchroot. Il contient les pilotes
Tegra (affichage DSI, GPU, audio, Joy-Con, stockage, énergie) et nécessite les
blobs NVIDIA.

Format : **uImage U-Boot**, pas `Image` brut. Un noyau mainline ne démarrera pas
correctement ici (pas de pilote d'affichage).

### 7. Initramfs Switchroot

- recherche la partition par label (`id=OSWITCH`) ;
- monte le rootfs (`ext4`) ;
- vérifie `/etc/switchroot_version.conf` ;
- exécute `switch_root`.

Sans le fichier marqueur : `<dev> not a switchroot installation...`.

Contrainte ext4 : le noyau 4.9 ne connaît pas `orphan_file` ni
`metadata_csum_seed`. `build-image.sh` les désactive.

### 8. rootfs Arch Linux ARM — le point bloquant

Arch fournit systemd 261. systemd exige un noyau ≥ 4.15 et cgroup v2. Le noyau
Switchroot est 4.9.140 : **systemd ne démarre pas**.

Conséquences concrètes :

- pas de `NetworkManager` géré par systemd ;
- pas de session `uwsm` ;
- pas de `omarchyswitch-firstboot.service` ;
- pas de `graphical.target`.

Options (détaillées dans l'[ADR 0004](adr/0004-systemd-kernel-compatibility.md)) :

1. noyau mainline + patches Switchroot (support écran à valider) ;
2. init alternative (script PID 1, comme le projet `alarm-tegra-x1`) ;
3. patch de systemd / rc.local — **non viable** sur une base Arch maintenue.

## Table des symptômes

| Symptôme | Étape | Cause probable |
|---|---|---|
| Retour au menu hekate | 2 | fichier `bootloader/sys/l4t/` manquant |
| `BL31 missing` | 3 | `bl31.bin` absent |
| Retour au menu après sélection | 5 | `boot.scr` échoue (fichier manquant, adresse) |
| Écran noir, LED active | 6 | noyau absent/incompatible, ou DTB incorrect |
| Écran noir avec log noyau | 6-7 | pilote d'affichage ou initramfs |
| `failed to mount rootfs` | 7 | label ext4 ≠ `id=`, ou options ext4 incompatibles |
| `not a switchroot installation` | 7 | `/etc/switchroot_version.conf` absent |
| Arrêt après initramfs | 8 | systemd incompatible (attendu, voir ADR 0004) |

## Références

- hekate README : <https://github.com/CTCaer/hekate/blob/master/README.md>
- Switchroot bootstack : <https://wiki.switchroot.org/wiki/linux/linux-bootstack-documentation>
- Clés `.ini` : `README_CONFIG.txt` du bootstack Switchroot
