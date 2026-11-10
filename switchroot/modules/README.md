# `switchroot/modules/` — modules noyau

**Contenu attendu :** l'arborescence `/usr/lib/modules/<version>/` du noyau L4T
utilisé, copiée telle quelle.

```text
switchroot/modules/
└── 4.9.140-l4t/
    ├── kernel/
    │   ├── drivers/net/wireless/broadcom/brcmfmac/brcmfmac.ko
    │   ├── drivers/bluetooth/hci_uart.ko
    │   ├── drivers/gpu/drm/tegra/...
    │   ├── drivers/input/...
    │   └── ...
    └── modules.dep, modules.alias, ...
```

## Règle absolue

Les modules doivent provenir **exactement** de la même compilation que
`uImage`. Un décalage produit :

- un module qui refuse de se charger (`invalid module format`) ;
- ou pire, un module qui se charge et corrompt la mémoire.

`integrate-switchroot.sh` compare le nom de version des modules avec
`L4T_KERNEL_VERSION` de `configs/versions.lock` et avertit en cas d'écart.

## Origine

Extraction depuis l'image rootfs Switchroot (lecture seule, root requis) :

```bash
sudo mount -o loop,ro switchroot-rootfs.img /mnt/swr
sudo cp -a /mnt/swr/lib/modules/. switchroot/modules/
sudo umount /mnt/swr
./switchroot/scripts/import-components.sh --from switchroot
```

## Modules attendus pour un système complet

Cette liste est une **attente documentée**, pas une garantie : elle dépend de la
configuration du noyau Switchroot.

| Fonction | Modules (noms upstream) |
|---|---|
| Wi-Fi | `brcmfmac`, `brcmutil`, `cfg80211` |
| Bluetooth | `bluetooth`, `hci_uart`, `btbcm` |
| Audio | `snd_soc_tegra210_*`, `snd_hda_tegra` |
| GPU | `tegra_drm`, `host1x`, `nvhost_*` |
| Joy-Con | `hid_nintendo` (ou driver Switchroot équivalent) |
| Tactile | `stmfts` (ou intégré au noyau) |
| Stockage | `sdhci_tegra`, `mmc_block` |
| Énergie | `max77620_regulator`, `tegra_soctherm`, `tegra_bpmp_thermal` |

Vérifier après intégration :

```bash
ls build/output/rootfs/usr/lib/modules/*/kernel/drivers/net/wireless/broadcom/brcmfmac/
```

Absence de `brcmfmac.ko` : le Wi-Fi ne fonctionnera pas, quelle que soit la
configuration réseau.
