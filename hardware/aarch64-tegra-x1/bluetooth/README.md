# Bluetooth — BCM2076

## Matériel

| Élément | Détail |
|---|---|
| Puce | Broadcom BCM2076 (combinée avec le Wi-Fi) |
| Bus | UART (H4) + GPIO de réveil |
| Firmware | patch `.hcd` Broadcom |
| Pile | BlueZ (`bluetoothd`) |

## Prérequis

1. **UART** configuré dans le DTB (broche, vitesse, flow control).
2. **Module** `hci_uart` + `btbcm` (noyau Switchroot).
3. **Firmware** `.hcd` correspondant à la révision de la puce, dans
   `/lib/firmware/brcm/`.
4. **Attachement** : soit le noyau expose directement `hci0`, soit il faut
   `hciattach` / `btattach` au démarrage (selon la configuration Switchroot).

## Vérification

```bash
dmesg | grep -iE 'bluetooth|hci|btbcm'
hciconfig -a        # ou: bluetoothctl show
systemctl status bluetooth
```

`hci0` absent : l'UART n'est pas attaché ou le firmware manque. Vérifier
`dmesg` avant de toucher à BlueZ.

## Interaction avec le Wi-Fi

Wi-Fi et Bluetooth partagent la même puce et souvent la même antenne :

- l'USB3 activé dégrade fortement le 2,4 GHz et le Bluetooth ;
- le mode ERTM peut gêner certaines manettes Xbox (`bt_ertm_disable=1`).

Ces réglages sont des clés hekate documentées, pas des valeurs par défaut du
projet.

## Ce qui manque dans la base 0.1.0

- Firmware `.hcd` (fourni par le BSP Switchroot).
- Dump de pairing des Joy-Con (données personnelles, à faire par l'utilisateur).
- Tout test réel : aucun périphérique Bluetooth n'a été associé.
