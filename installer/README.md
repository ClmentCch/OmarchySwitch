# `installer/` — installateur

L'installateur d'OmarchySwitch s'exécute **sur un ordinateur hôte**, pas sur la
console : il écrit une image ou prépare une carte SD. Il n'y a pas
d'installateur graphique, et ce n'est pas un oubli : la console ne démarre pas
tant que la carte n'est pas écrite.

| Chemin | Rôle |
|---|---|
| `scripts/install.sh` | Écrit une image vérifiée sur un périphérique bloc |
| `partition/partition-sd.sh` | Partitionne et formate une carte (usage avancé) |
| `rootfs/first-boot.sh` | Rappel du script exécuté au premier démarrage (source dans `archlinux/rootfs/firstboot/`) |

## Deux méthodes

### A. Image complète (recommandée)

```bash
sudo ./scripts/build-image.sh --rootfs build/output/rootfs \
     --output build/output/omarchyswitch-0.1.0.img
sudo ./installer/scripts/install.sh --device /dev/sdX \
     --image build/output/omarchyswitch-0.1.0.img
```

`install.sh` vérifie l'empreinte si un fichier `.sha256` accompagne l'image,
refuse un périphérique monté, demande confirmation et synchronise après écriture.

### B. Partitionnement manuel (avancé)

```bash
sudo ./installer/partition/partition-sd.sh --device /dev/sdX --yes
```

Puis copier l'arbre de boot et le rootfs à la main. Cette voie existe pour les
utilisateurs qui veulent une disposition particulière ; elle est plus risquée et
n'est pas testée.

## Sécurité

- Rien ne s'exécute sans `--yes` sur un périphérique bloc.
- Un périphérique monté est refusé, pas démonté de force.
- Le script affiche le modèle et la taille du périphérique avant confirmation :
  c'est le dernier garde-fou contre l'écrasement du mauvais disque.
- Aucun script n'écrit sur l'eMMC interne de la console : la cible est la SD.

## Ce qui n'est pas fourni

- Pas d'installateur depuis la console elle-même.
- Pas de support du dual-boot avec Horizon OS sur la même carte
  (voir `docs/06-known-limitations.md`).
- Pas de chiffrement du rootfs : ce serait une fonctionnalité à part entière,
  avec ses propres risques de perte de données sur une console.
