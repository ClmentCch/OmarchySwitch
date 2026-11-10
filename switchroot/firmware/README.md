# `switchroot/firmware/` — firmware matériel

**Contenu attendu :** l'arborescence `/lib/firmware/` nécessaire aux pilotes
Tegra X1 et aux périphériques de la console.

## Fichiers critiques

| Chemin | Matériel | Sans lui |
|---|---|---|
| `brcmfmac4356-pcie.bin` | Wi-Fi Broadcom BCM4356 | `brcmfmac` ne charge pas le firmware, pas de Wi-Fi |
| `brcmfmac4356-pcie.txt` | calibration/NVRAM Wi-Fi | association impossible, débit nul |
| `brcm/brcmfmac4356-pcie.*.bin` | firmware alternatifs selon révision | idem |
| `brcm/BCM4356A3.hcd` (ou équivalent) | Bluetooth | pas de Bluetooth |
| `nvidia/tegra210/vic04_ucode.bin` | VIC (décodage vidéo) | pas d'accélération vidéo |
| `nvidia/tegra210/xusb.bin` | XUSB (USB device) | USB gadget instable |
| firmware BPMP (`bpmpfw*.bin`) | gestion des clocks/rails | fourni à hekate, pas au noyau |

## Licences

Les firmwares Broadcom sont redistribuables sous leurs termes d'origine
(`linux-firmware` les contient pour d'autres plateformes). En revanche les blobs
NVIDIA du BSP L4T sont **propriétaires** : ils ne sont pas redistribués par ce
dépôt et ne doivent pas être publiés dans une release.

## Origine

1. Image rootfs Switchroot (`/lib/firmware/`) — voie recommandée, cohérente avec
   le noyau.
2. `linux-firmware` d'Arch pour les fichiers Broadcom génériques (attention :
   la variante `4356-pcie.txt` calibrée pour la Switch vient de Switchroot).

```bash
sudo mount -o loop,ro switchroot-rootfs.img /mnt/swr
sudo cp -a /mnt/swr/lib/firmware/. switchroot/firmware/
sudo umount /mnt/swr
./switchroot/scripts/import-components.sh --from switchroot
```

## Vérification

```bash
find switchroot/firmware -name 'brcmfmac4356*' -printf '%f %s bytes\n'
```

Après intégration, `integrate-switchroot.sh` vérifie la présence de
`brcmfmac4356-pcie.bin` et `.txt` dans le rootfs et avertit sinon.

## Piège connu

Un firmware Wi-Fi absent ne provoque pas d'erreur visible au démarrage : l'interface
`wlan0` n'apparaît simplement jamais. Vérifier `dmesg | grep brcmfmac` sur la
console (ou via le log USB de l'entrée debug hekate).
