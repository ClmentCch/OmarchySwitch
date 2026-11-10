# `scripts/` — scripts principaux

Tous les scripts sont en Bash, commencent par `set -euo pipefail`, acceptent
`--help` et refusent de s'exécuter si l'architecture cible n'est pas `aarch64`.

| Script | Rôle | Root | Réseau | Écrit sur un disque |
|---|---|---:|---:|---:|
| `bootstrap-arch.sh` | Vérifie l'hôte, télécharge le tarball Arch Linux ARM, vérifie son SHA-256 | non | oui | non |
| `build-rootfs.sh` | Extrait le rootfs aarch64, initialise pacman, installe les paquets de base, applique l'overlay, crée l'utilisateur | oui | oui | non |
| `integrate-switchroot.sh` | Vérifie et copie les composants Switchroot, construit l'arbre de boot FAT, contrôle noyau/modules/firmware | oui | non | non |
| `integrate-omarchy.sh` | Ajoute le dépôt Omarchy aarch64, installe les paquets, applique les configurations | oui | oui | non |
| `install-desktop.sh` | Installe la pile graphique/audio/réseau, configure uwsm et l'autologin tty1 | oui | oui | non |
| `validate-architecture.sh` | Contrôles statiques du dépôt (structure, syntaxe, aarch64, manifests, secrets, liens) | non | non | non |
| `build-image.sh` | Assemble l'image GPT (FAT32 + ext4), ou écrit sur une carte avec `--device` + `--yes` | oui | non | **oui** |
| `package-release.sh` | Produit et vérifie `dist/OmarchySwitch-Base-v<version>.zip` | non | non | non |

## Bibliothèque commune

`lib/common.sh` fournit :

- chargement de la configuration (`configs/omarchyswitch.conf` + `local.conf` + `versions.lock`) ;
- journalisation colorée et fichier de log par exécution (`build/output/logs/`) ;
- **gardes d'architecture** : `osw_is_aarch64_elf`, `osw_elf_machine`, `osw_require_aarch64_tree`, `osw_assert_no_foreign_elf` ;
- vérification `binfmt_misc`/qemu pour construire de l'aarch64 sur hôte x86_64 ;
- empreintes de fichiers **et d'arborescences** (`osw_sha256`), nécessaire pour vérifier les répertoires de modules ;
- parsing TOML via `python3` + `tomllib`, pour que les manifests soient la source de vérité.

Elle s'exécute aussi directement :

```bash
./scripts/lib/common.sh --print-config
```

## Ordre d'exécution

```text
bootstrap-arch.sh
      │
      ▼
build-rootfs.sh ──► integrate-switchroot.sh ──► integrate-omarchy.sh
                                                        │
                                                        ▼
                                              install-desktop.sh
                                                        │
                                                        ▼
                                                build-image.sh
                                                        │
                                                        ▼
                                               package-release.sh
```

`validate-architecture.sh` peut être exécuté à tout moment, y compris avant
toute installation : il ne nécessite ni root, ni réseau, ni matériel.

## Ce que ces scripts ne font pas

- Ils **ne récupèrent pas** les binaires Switchroot à votre place : les URL des
  releases peuvent changer et les blobs NVIDIA ne sont pas redistribuables.
  L'intégration est donc explicite, vérifiée par empreinte, et documentée dans
  `switchroot/README.md`.
- Ils **ne promettent pas** que la console démarrera. Aucun test matériel n'a
  été effectué pour la version 0.1.0.
- Ils **ne contournent pas** l'incompatibilité systemd / noyau 4.9 : voir
  `docs/adr/0004-systemd-kernel-compatibility.md`.
