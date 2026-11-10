# Tactile — STMicroelectronics `stmfts`

## Matériel

| Élément | Détail |
|---|---|
| Contrôleur | STMFTS (STMicroelectronics), I²C adresse `0x49` |
| Dalle | capacitive, multi-touch, associée au panneau JDI |
| Alimentation | rails décrits dans le DTB |
| Pilote | `stmfts` |

## Point délicat : la calibration au boot

Le bootstack hekate expose `touch_skip_tuning=1` pour désactiver la
calibration au démarrage. Sur certaines dalles (nappe flex abîmée, révision
particulière), la calibration échoue et le tactile reste muet. Dans ce cas
seulement, activer la clé dans l'entrée hekate.

Valeur par défaut du projet : **0** (calibration activée), car c'est le
comportement normal.

## Point délicat : l'alimentation

Sur mainline, le pilote `stmfts` désactive ses alimentations en cas d'échec de
sonde, ce qui fait disparaître le contrôleur du bus. Le correctif consiste à
maintenir l'alimentation active. Sur le noyau L4T Switchroot, ce comportement
est déjà géré.

## Rotation et mapping

La dalle est montée en portrait. Après rotation de l'affichage, la zone tactile
doit être transformée de la même façon, sinon les coordonnées sont tournées de
90°. Côté Hyprland :

```ini
input {
    touchdevice {
        transform = 1   # à ajuster selon l'orientation réelle
    }
}
```

La valeur exacte dépend du sens de rotation retenu : c'est un réglage à
déterminer sur la console, pas une constante du projet.

## Vérification

```bash
dmesg | grep -i stmfts
ls /dev/input/
evtest            # sélectionner l'événement tactile et toucher l'écran
libinput debug-events
```

## État

**prépa** : le pilote est attendu via le noyau/DTB Switchroot, la configuration
du compositeur est écrite, aucune mesure n'a été faite.
