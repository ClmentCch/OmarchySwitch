# `applications/` — applications Switchroot et applications système

Deux catégories, deux traitements :

| Dossier | Contenu | Traitement |
|---|---|---|
| `switchroot/` | Outils de l'écosystème Switchroot (Ubuntu) | Analyse, manifeste, statut de portage |
| `system/` | Paquets Arch utiles sur la console | Liste installée par les scripts |

Le guide [`PORTING.md`](PORTING.md) décrit la méthode pour transformer un outil
Ubuntu `.deb` ou un script en paquet Arch `aarch64`.

## Principe

Une application n'est déclarée « portée » que si :

1. sa licence autorise la redistribution ou l'usage prévu ;
2. elle se compile ou s'installe pour `aarch64` ;
3. ses dépendances existent sur Arch Linux ARM ;
4. elle a été **exécutée sur la console**.

Tant que les points 3 et 4 ne sont pas satisfaits, le statut reste `a_porter` ou
`bloque` dans le manifeste. Voir
[`switchroot/manifest.toml`](switchroot/manifest.toml).

## Pourquoi aucun `.deb` n'est converti ici

Convertir un `.deb` Ubuntu en paquet Arch est possible (`debtap`), mais :

- les binaires Ubuntu Bionic sont liés à des versions de `glibc` et de
  bibliothèques NVIDIA qui n'existent pas sur Arch ARM ;
- le noyau cible diffère ;
- `debtap` produit souvent des paquets qui s'installent mais ne démarrent pas.

La bonne approche est de recompiler depuis les sources, ou d'utiliser les
paquets `aarch64` déjà publiés par l'écosystème Arch. C'est ce que décrit
`PORTING.md`.

## Ce qui existe déjà côté Arch ARM

| Besoin | Paquet Arch |
|---|---|
| Manettes | `bluez`, `bluez-utils`, `joystick` |
| Émulation | `retroarch`, cœurs `libretro-*` |
| Streaming | `moonlight-qt` (disponibilité aarch64 à vérifier) |
| Outils système | `evtest`, `htop`, `iw`, `brightnessctl` |
| Navigateur | `firefox`, `chromium` (poids à évaluer sur 4 Gio de RAM) |

La disponibilité exacte est vérifiée à l'installation : `pacman` échoue
explicitement si un paquet manque sur le miroir ARM.
