# Joy-Con — attachés et Bluetooth

## Deux modes distincts

| Mode | Transport | Dépendances |
|---|---|---|
| Attachés à la console | rails + I²C, charge | DTB (rails), driver HID du noyau |
| Détachés | Bluetooth | firmware BT, informations de pairing |

## Informations de pairing

Les Joy-Con sont appairés en usine avec la console sous Horizon OS. Sous Linux,
il faut exporter ces informations depuis hekate :

> hekate → **Tools** → **Dump Joy-Con BT pairing** (le libellé exact dépend de
> la version ; voir la documentation hekate).

Le fichier obtenu doit être placé là où le driver Bluetooth de Switchroot
l'attend (généralement `/var/lib/bluetooth/...`). **Ce projet ne fournit pas ce
fichier** : il contient des clés propres à votre console, donc des données
personnelles qui n'ont rien à faire dans un dépôt.

## Ce que fait OmarchySwitch

- Rien de spécifique pour l'instant : les Joy-Con sont gérés par le noyau et
  BlueZ, comme n'importe quelle manette.
- `bluez` et `bluez-utils` sont installés, `bluetooth.service` est activé par
  `install-desktop.sh`.

## Ce qui manque

- Driver HID du noyau Switchroot (dans les modules à importer).
- Dump de pairing hekate (à faire par l'utilisateur, sur sa console).
- Test réel : aucun Joy-Con n'a été connecté pendant le développement.

## Vérification

```bash
# manettes HID détectées
ls /sys/bus/hid/devices/
evtest                     # choisir l'entrée correspondant au Joy-Con

# Bluetooth
bluetoothctl
  list
  scan on
```

## Notes de conception

Un futur `applications/` pourrait inclure un outil de mappage Joy-Con → manette
Xbox pour les jeux. Ce n'est pas dans la base 0.1.0 : mieux vaut un système qui
démarre qu'un ensemble de promesses.
