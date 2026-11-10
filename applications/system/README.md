# Applications système

Liste des paquets Arch installés en plus du socle, avec leur justification.
Le fichier [`packages.txt`](packages.txt) est la source utilisée par les scripts
(installation manuelle ou ajout à `build/manifests/desktop-packages.txt`).

## Catégories

| Catégorie | Paquets | Pourquoi |
|---|---|---|
| Diagnostic | `evtest`, `usbutils`, `pciutils`, `lm_sensors` | vérifier le matériel sans dépendre du bureau |
| Réseau | `iw`, `wpa_supplicant`, `networkmanager` | Wi-Fi, y compris en console |
| Énergie | `upower`, `brightnessctl` | batterie et luminosité |
| Fichiers | `less`, `nano`, `rsync` | usage courant en console |
| Développement | `git`, `base-devel` (optionnel) | construire des paquets sur la console |

## Prudence sur la RAM

La console partage 4 Gio entre CPU et GPU. Éviter les environnements lourds et
les navigateurs à nombreux onglets. Un navigateur reste installable, mais ce
n'est pas un prérequis de la base.

## Ce qui n'est pas inclus

- Aucun jeu, aucun émulateur : ce sont des choix utilisateur.
- Aucun outil propriétaire.
- Aucun paquet `x86_64` (interdit et vérifié par la CI).
