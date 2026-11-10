# `configs/` — configuration centrale

Deux fichiers, deux rôles :

| Fichier | Rôle | Versionné |
|---|---|---|
| `omarchyswitch.conf` | Valeurs par défaut : identité, cible matérielle, dépôts, disposition disque, comportement de build. | Oui |
| `versions.lock` | Versions upstream épinglées et contraintes de compatibilité factuelles (noyau, Omarchy, hekate, Switchroot). | Oui |
| `local.conf` | Surcharges propres à votre machine (chemin de sources, miroir préféré, taille d'image). | **Non** (`.gitignore`) |

## Comment la configuration est chargée

`scripts/lib/common.sh` :

1. détecte la racine du dépôt (remontée jusqu'à `VERSION`) ;
2. source `configs/omarchyswitch.conf` ;
3. source `configs/local.conf` s'il existe ;
4. exporte les variables utilisées par les scripts.

Aucune valeur n'est lue depuis l'environnement du shell : ce qui est exécuté
est toujours visible dans ces deux fichiers. C'est volontaire — un build qui
change de comportement selon une variable d'environnement oubliée est un build
impossible à reproduire.

## Exemple de `configs/local.conf`

```bash
# Utiliser les sources déjà téléchargées
OMARCHY_SRC_DIR="/srv/src/omarchy"
# Image plus grande pour un rootfs Omarchy complet
IMAGE_SIZE="24G"
# Miroir proche
ALARM_MIRROR="http://eu.mirror.archlinuxarm.org"
```

## Valeurs sensibles

- `ALARM_TARBALL_SHA256` est **vide** par défaut : Arch Linux ARM régénère son
  tarball « latest » et l'empreinte change. `build-rootfs.sh` refuse de
  continuer sans empreinte, sauf `--allow-unpinned-tarball`, et dans ce cas il
  affiche l'empreinte téléchargée pour que vous puissiez l'épingler.
- `ROOT_FS_LABEL` doit rester ≤ 7 caractères : l'entrée hekate utilise
  `id=`, limité à 7 caractères par le bootloader. La valeur `OSWITCH` est
  volontaire.
- `OMARCHY_INSTALL_KERNEL=0` n'est pas une option de confort : le noyau
  `linux-omarchy` ne supporte pas Tegra X1 et remplacerait le noyau Switchroot.

## Vérification

```bash
./scripts/lib/common.sh --print-config   # configuration effective
./scripts/validate-architecture.sh       # cohérence config ↔ fichiers
```
