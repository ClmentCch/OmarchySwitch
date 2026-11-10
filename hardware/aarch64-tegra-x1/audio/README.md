# Audio — haut-parleurs, casque, micro

## Matériel

| Élément | Détail |
|---|---|
| Codec | Realtek ALC5639 (I²C/I²S) |
| Amplificateur | MAX98357 (haut-parleurs) |
| Sortie casque | jack 3,5 mm, détection par GPIO/ADC |
| Micro | via le codec, chemins numériques Tegra |

## Pile logicielle prévue

```text
Application
  └─ PipeWire (serveur)
       └─ WirePlumber (gestion des périphériques)
            └─ ALSA (UCM pour Tegra ?)
                 └─ noyau : snd_soc_tegra210_* + codec ALC5639
```

Les paquets `pipewire`, `pipewire-pulse` et `wireplumber` sont installés par
`omarchyswitch-base` et `install-desktop.sh` active les unités utilisateur.

## Ce qui manque

- Les modules `snd_soc_tegra210_*` doivent venir du noyau Switchroot.
- Le routage ALSA (fichiers UCM) dépend du BSP ; il n'est pas fourni par Arch.
- Aucun test audio n'a été effectué.

## Vérification sur console (une fois le noyau en place)

```bash
aplay -l                       # cartes et périphériques détectés
wpctl status                   # état PipeWire
speaker-test -c 2 -t sine -l 1 # test haut-parleurs
amixer scontrols               # contrôles ALSA exposés
```

## Notes

- Ne pas installer `pulseaudio` : Omarchy (et ce projet) utilisent PipeWire.
- Un `aplay -l` vide signifie que le pilote/codec n'est pas chargé : vérifier le
  DTB et les modules avant de toucher à PipeWire.
- Le jack casque peut nécessiter une règle udev ou un réglage UCM ; sans
  documentation du BSP, ce point reste à tester.
