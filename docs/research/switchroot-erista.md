# Recherche — Switchroot et Erista

Vérifié le **2026-11-10**.

## Ce qui a été lu

| Source | URL |
|---|---|
| Wiki Switchroot (bootstack) | <https://wiki.switchroot.org/wiki/linux/linux-bootstack-documentation> |
| Wiki Switchroot (features) | <https://wiki.switchroot.org/wiki/linux/linux-features> |
| Guides d'installation | <https://wiki.switchroot.org/wiki/linux/l4t-ubuntu-bionic-installation-guide> |
| hekate README | <https://github.com/CTCaer/hekate/blob/master/README.md> |
| Clés `.ini` L4T | `README_CONFIG.txt` du bootstack Switchroot |
| Projet GitLab | <https://gitlab.com/switchroot> |

## Chaîne de démarrage (confirmée par la documentation)

```text
hekate (payload RCM)
 └─ L4T Loader : prépare les fichiers, transmet les clés .ini
     └─ ATF (bl31.bin)
         └─ U-Boot (bl33.bin) : exécute boot.scr
             └─ uImage + nx-plat.dtimg + initramfs
                 └─ initramfs : monte le rootfs, switch_root
```

hekate **ne démarre pas** un noyau brut : le L4T Loader est obligatoire.

## Fichiers du boot prefix (confirmés)

`uImage`, `initramfs`, `nx-plat.dtimg`, `boot.scr`, `bl31.bin`, `bl33.bin`.

Fichiers hekate nécessaires (`bootloader/sys/`) : `nyx.bin`, `res.pak`,
`libsys_lp0.bso`, `libsys_minerva.bso`, `sys/l4t/bpmpfw*.bin`,
`sys/l4t/mtc_tbl*.bin`.

Message d'erreur associé : `missing lp0 (sleep) lib / missing minerva lib /
update bootloader folder!`.

## Clés `.ini` documentées (extraits vérifiés)

| Clé | Valeurs | Note |
|---|---|---|
| `l4t` | `1` | obligatoire |
| `boot_prefixes` | `/switchroot/<distro>/` | obligatoire |
| `id` | label FS, **7 caractères max** | remplace `rootdev` si trouvé |
| `rootdev` | `mmcblk0p2` | repli |
| `rootfstype` | `ext4` | |
| `rootlabel_retries` | nombre × 200 ms | utile en USB |
| `r2p_action` | `self`, `bootloader`, `normal` | |
| `fbconsole` | `0` dalle, `1` DP/HDMI, `9` aucun | |
| `uart_port` | `0`-`4` (4 = USB) | seule voie de log sur console retail |
| `earlycon` | `0`/`1` | |
| `touch_skip_tuning` | `0`/`1` | dalles dont la calibration échoue |
| `wifi_disable_vht80` | `0`/`1` | instabilité firmware |
| `cec_disable`, `usb3_enable`, `4k60_disable` | `0`/`1` | dock |
| `ram_oc`, `ram_oc_vdd2`, `ram_oc_vddq` | fréquence/mV | overclock, non utilisé |
| `dvfsb`, `gpu_dvfsc`, `limit_gpu_clk` | `0`/`1` | **Mariko uniquement** |

## Contraintes techniques confirmées par des sources tierces

| Contrainte | Source | Statut |
|---|---|---|
| Le noyau L4T est 4.9.140 | dépôts/tags Switchroot | confirmé |
| ext4 sans `orphan_file`/`metadata_csum_seed` pour 4.9 | projet `alarm-tegra-x1` | rapporté, cohérent avec l'âge du noyau |
| L'initramfs exige `/etc/switchroot_version.conf` | projet `alarm-tegra-x1` | rapporté |
| systemd 261 ne démarre pas sur 4.9 (cgroup v2, ≥ 4.15) | projet `alarm-tegra-x1` + documentation systemd | confirmé par la doc systemd |
| Le pilote d'écran DSI n'existe pas en mainline nu | projet `alarm-tegra-x1`, patches Switchroot | rapporté |
| L'Arch L4S est déprécié (ABI xorg vs BSP Tegra210) | NH Switch Guide | rapporté |

## Dépôts Switchroot vérifiés (API GitLab)

| Projet | Branche par défaut |
|---|---|
| `switchroot/kernel/l4t-kernel-4.9` | `lineage-19.1` |
| `switchroot/kernel/l4t-kernel-nvidia` | `lineage-19.1` |
| `switchroot/kernel/l4t-platform-t210-switch` | `linux-5.0.0-dev` |
| `switchroot/kernel/l4t-device-tree-overlays` | `master` |
| `switchroot/kernel/l4t-initramfs` | `master` |
| `switchroot/kernel/mainline-kernel` | `switch-dev` |
| `switchroot/bootstack/switch-uboot` | `linux-hekatf` |
| `switchroot/bootstack/switch-atf` | `switch-v4-atf2.6` |
| `switchroot/bootstack/switch-uboot-scripts` | `master` |

Tags du noyau L4T consultés : `linux-5.1.0_r2` (2023-04-13), `linux-5.1.0`,
`linux-5.0.0`, `linux-3.4.0`, `linux-3.3.0`, ...

## Décisions qui en découlent

1. Ne pas tenter de noyau Arch : aucun n'existe pour Tegra X1 avec support
   matériel complet.
2. Conserver la chaîne Switchroot (ADR 0002).
3. Refuser les binaires dans le dépôt (ADR 0003).
4. Traiter systemd comme un problème séparé et bloquant (ADR 0004).

## Incertitudes restantes

- Le nom exact du fichier `bpmpfw` varie selon la révision (`bpmpfw.bin`,
  `bpmpfw_b01.bin`) : le manifeste accepte un motif.
- Les noms de firmware Bluetooth (`.hcd`) dépendent de la révision de la puce.
- Les modules exacts fournis par le noyau Switchroot dépendent de sa config ;
  `switchroot/modules/README.md` liste des **attentes**, pas une garantie.
