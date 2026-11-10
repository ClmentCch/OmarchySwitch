# Wi-Fi — Broadcom BCM4356 (PCIe)

## Matériel

| Élément | Détail |
|---|---|
| Puce | Broadcom BCM4356 (2,4/5 GHz, 2×2) |
| Bus | PCIe (contrôleur Tegra) |
| Alimentation | rail `ldo1` du MAX77620 |
| Pilote | `brcmfmac` |

## Prérequis, dans l'ordre

1. **DTB** décrivant le contrôleur PCIe et le rail `ldo1` ; sans l'alimentation,
   le lien PCIe ne s'entraîne pas.
2. **Modules** : `brcmfmac`, `brcmutil`, `cfg80211` (issus du noyau Switchroot).
3. **Firmware** : `brcmfmac4356-pcie.bin` et `brcmfmac4356-pcie.txt` (NVRAM
   calibrée pour la Switch).
4. **NetworkManager** : installé et activé par `install-desktop.sh`.

## Piège principal

Sur mainline, activer le PCIe sans le rail `ldo1` provoque une `SError`
asynchrone qui tue le noyau. Sur le noyau L4T Switchroot, ce chemin est déjà
géré — à condition d'utiliser le DTB Switchroot, pas un DTB générique Tegra.

## Vérification

```bash
dmesg | grep -i brcmfmac
ip link show
nmcli device status
```

Attendu : une interface `wlan0`. Si `dmesg` affiche `brcmfmac: firmware not
found`, le firmware manque ; si rien n'apparaît du tout, c'est le PCIe ou le
DTB.

## Clés hekate liées

| Clé | Effet |
|---|---|
| `wifi_disable_vht80=1` | désactive l'agrégation VHT80/160 (instabilité connue sur certains firmwares) |
| `usb3_enable=1` | peut dégrader fortement le Wi-Fi 2,4 GHz et le Bluetooth |

Aucune n'est activée par défaut.

## Configuration réseau

`NetworkManager` est le gestionnaire prévu (Omarchy l'utilise). Le premier
démarrage ne configure **aucun** réseau : il n'existe pas de fichier de
credentials dans ce dépôt, volontairement.
