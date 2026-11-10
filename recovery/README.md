# `recovery/` — diagnostic et restauration

Deux objectifs, tous deux exécutés depuis un ordinateur hôte avec la carte SD
montée (ou son image) :

| Dossier | Rôle |
|---|---|
| `diagnostics/` | Rassembler l'état de la carte et des fichiers de boot, sans donnée personnelle |
| `restore/` | Remettre une configuration de démarrage saine, sans toucher au rootfs |

## Pourquoi depuis l'hôte

Une console qui ne démarre pas n'a pas de console série utilisable. Les seules
sources d'information sont :

1. la partition FAT (fichiers de boot, entrées hekate) ;
2. le rootfs s'il a été monté au moins une fois (journaux) ;
3. l'écran, uniquement si `fbconsole=0` (entrée debug).

`diagnostics/collect.sh` exploite les deux premières.

## Ce que la récupération ne fait pas

- Elle ne répare pas un rootfs corrompu en place (utiliser `fsck`, puis
  reconstruire si nécessaire).
- Elle ne restaure pas les binaires Switchroot (non redistribués).
- Elle ne contourne pas un problème de compatibilité noyau/systemd.

## Ordre de diagnostic recommandé

```text
1. La carte est-elle lisible ?         lsblk, fsck
2. Les fichiers de boot sont-ils là ?  diagnostics/collect.sh
3. hekate trouve-t-il ses fichiers ?   bootloader/sys/l4t/*, sys/*.bso
4. Les entrées .ini sont-elles justes ? labels, boot_prefixes
5. Le noyau démarre-t-il ?             entrée debug (fbconsole=0) ou UART USB
6. Le rootfs est-il monté ?            initramfs, switchroot_version.conf
7. systemd démarre-t-il ?              bloque connu (noyau 4.9)
```

Chaque étape élimine une classe de causes ; sauter directement à la 7 fait
perdre des heures.
