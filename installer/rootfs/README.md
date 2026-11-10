# `installer/rootfs/` — contenu lié au rootfs de l'installateur

Ce dossier ne contient pas de rootfs : le rootfs est construit par
`scripts/build-rootfs.sh` depuis le tarball Arch Linux ARM. Il contient le
script de premier démarrage utilisé par l'installateur pour préparer la carte.

| Fichier | Rôle |
|---|---|
| `first-boot.sh` | Copie de référence de `archlinux/rootfs/firstboot/omarchyswitch-firstboot.sh` |

## Pourquoi une copie

`archlinux/rootfs/firstboot/` est la **source** installée dans le rootfs.
`installer/rootfs/first-boot.sh` est le point d'entrée utilisé par les scripts
d'installation pour vérifier ce qui sera exécuté au premier démarrage, sans
avoir à connaître l'arborescence du rootfs.

Les deux fichiers doivent rester identiques. `scripts/validate-architecture.sh`
vérifie leur présence ; la synchronisation est la responsabilité du mainteneur
(une divergence silencieuse serait pire qu'une duplication assumée).

## Ce que fait le premier démarrage

1. agrandit la partition racine (`resize2fs`) ;
2. génère `/etc/machine-id` ;
3. applique le hostname ;
4. écrit des avertissements si modules/firmware manquent ;
5. dépose une note `FIRST-BOOT.md` dans le home de chaque utilisateur ;
6. se désactive.

Aucune interaction, aucun mot de passe par défaut, aucune connexion réseau
automatique.
