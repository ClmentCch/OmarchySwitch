# `archlinux/rootfs/` — overlay et premier démarrage

Deux mécanismes distincts :

| Chemin | Quand | Qui l'applique |
|---|---|---|
| `overlay/` | à la construction | `scripts/build-rootfs.sh` (copie telle quelle dans `/`) |
| `firstboot/` | au premier démarrage sur la console | unité `omarchyswitch-firstboot.service` |

## Overlay

```text
overlay/
├── etc/hostname                       # omarchyswitch
├── etc/os-release                     # identité de la distribution
├── etc/switchroot_version.conf        # marqueur exigé par l'initramfs Switchroot
├── etc/fstab.template                 # /etc/fstab, labels substitués au build
├── etc/resolv.conf                    # résolveur de secours pendant le chroot
└── etc/systemd/system/
    └── omarchyswitch-firstboot.service
```

Règles :

- **Aucun secret** dans l'overlay (pas de clé SSH, pas de mot de passe).
- **Aucun chemin de périphérique en dur** dans `fstab` : uniquement des labels
  (`LABEL=OSWITCH`, `LABEL=OMARCHYSW`), car la carte SD et l'eMMC changent de nom.
- `switchroot_version.conf` est **obligatoire** : l'initramfs Switchroot refuse
  `switch_root` si le fichier est absent.
- Le compte par défaut est créé verrouillé (pas de mot de passe connu) ; c'est
  le premier démarrage qui permet d'en définir un.

## Premier démarrage

`omarchyswitch-firstboot` est exécuté une fois par systemd. Il :

1. agrandit la partition racine à la taille de la carte (`resize2fs`) ;
2. génère `/etc/machine-id` s'il est vide ;
3. applique le hostname et le fuseau horaire ;
4. crée `/var/lib/omarchyswitch/` et son marqueur de fin ;
5. écrit un journal dans `/var/log/omarchyswitch-firstboot.log` ;
6. désactive son propre service.

Il ne demande **aucune interaction** : une console portable n'a pas de clavier au
démarrage. Le mot de passe utilisateur est défini ensuite, manuellement.

## Vérification après construction

```bash
test -f build/output/rootfs/etc/switchroot_version.conf
test -f build/output/rootfs/etc/fstab
grep -E 'LABEL=' build/output/rootfs/etc/fstab
```
