# `archlinux/rootfs/firstboot/`

## `omarchyswitch-firstboot.sh`

Script exécuté **une seule fois** sur la console, par
`omarchyswitch-firstboot.service`.

Installé par `scripts/build-rootfs.sh` sous
`/usr/local/sbin/omarchyswitch-firstboot`.

| Étape | Action | Pourquoi |
|---|---|---|
| 1 | `resize2fs` sur la racine | l'image peut être plus petite que la carte |
| 2 | `machine-id` si vide | journald et systemd en ont besoin |
| 3 | hostname | cohérence réseau |
| 4 | avertissements modules/firmware/Hyprland | un manque doit être visible dans un log |
| 5 | `~/FIRST-BOOT.md` | guider sans bloquer sur une invite |
| 6 | marqueur + désactivation | ne s'exécute qu'une fois |

## Choix de conception

- **Aucune interaction** : pas de clavier au démarrage, une invite bloquerait la
  session indéfiniment.
- **Aucun mot de passe par défaut** : le compte est verrouillé ; l'utilisateur en
  définit un consciemment.
- **Aucun réseau automatique** : les credentials Wi-Fi n'ont rien à faire dans
  une image.
- **Jamais fatal** : chaque étape vérifie ses préconditions et journalise ; un
  échec n'empêche pas le démarrage.

## Journal

`/var/log/omarchyswitch-firstboot.log`

En cas de problème, ce fichier (collecté par
`recovery/diagnostics/collect.sh`) est la première source d'information.

## Limite

Le script dépend de systemd, qui ne démarre pas sur le noyau 4.9 (voir
`docs/adr/0004-systemd-kernel-compatibility.md`). Il est donc écrit, installé et
activé, mais ne s'exécutera pas tant que ce point n'est pas résolu.
