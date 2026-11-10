# Affichage — dalle DSI et HDMI

## Matériel

| Élément | Détail |
|---|---|
| Dalle | JDI LPM062M326A, 6,2", 720×1280, interface DSI 4 lanes |
| Orientation | montée en portrait ; l'affichage paysage est obtenu par rotation |
| Rétroéclairage | PWM via le PMIC, piloté par le noyau |
| Dock | sortie DP/HDMI via USB-C, négociation CEC |

## Dépendances

- **Noyau** : pilote panneau + contrôleur DC/SOR/DSI du BSP L4T. Un noyau
  mainline n'a pas ce pilote : c'est la raison principale pour laquelle la base
  0.1.0 conserve le noyau Switchroot.
- **DTB** (`nx-plat.dtimg`) : décrit la dalle, les rails, le rétroéclairage.
  Sans lui, le noyau ne sait pas qu'un écran existe.
- **Initramfs** : peut afficher une image de démarrage ; désactivable via
  `fbconsole` dans l'entrée hekate.

## Configuration côté OmarchySwitch

`omarchy/configs/hypr/omarchyswitch.conf` déclare l'écran :

```ini
monitor = eDP-1, 1280x720@60, 0x0, 1
```

Points d'attention :

- **Pas de scaling fractionnaire** : le GM20B n'a pas les ressources pour du
  1.25× ou 1.5×. Rester en échelle 1 et dimensionner les polices.
- **Rotation** : si l'image apparaît à 90°, ajuster `transform` dans la
  configuration du moniteur plutôt que de modifier le DTB.
- **Touch** : la zone tactile doit suivre la rotation (`input` +
  `transform`), sinon le curseur part dans la mauvaise direction.

## Dock et HDMI

| Clé hekate | Effet |
|---|---|
| `cec_disable=1` | désactive la négociation CEC (écrans qui se réveillent mal) |
| `usb3_enable=1` | active l'USB3, au prix du Wi-Fi 2,4 GHz / Bluetooth |
| `4k60_disable=1` | désactive le 4K@60 (utile sur OLED, hors périmètre ici) |

Aucune de ces clés n'est activée par défaut dans ce projet : elles changent le
comportement matériel et doivent être validées sur une console.

## État

**prépa** : configuration écrite, jamais exécutée. Le premier test à faire est
l'entrée hekate `debug` (`fbconsole=0`), qui affiche le log noyau sur la dalle :
c'est le seul moyen de distinguer « pas de noyau » de « noyau démarré sans
pilote d'affichage ».
