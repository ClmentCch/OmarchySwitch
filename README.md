# OmarchySwitch

**Une distribution Linux indépendante pour la Nintendo Switch V1 (Erista), bâtie sur Arch Linux ARM64 et l'environnement Omarchy.**

| | |
|---|---|
| Nom officiel | OmarchySwitch |
| Nom abrégé | OmarchyS |
| Identifiant / nom de dossier | `omarchyswitch` |
| Version de cette base | `0.1.0` (pre-release de développement) |
| Cible matérielle | Nintendo Switch V1 — HAC-001, SoC Tegra X1 (T210, ODNX02-A2), Erista |
| Système principal | Arch Linux ARM (aarch64) |
| Environnement | Omarchy 4.5.0 (MIT) adapté ARM64 |
| Chaîne de démarrage | hekate 6.5.4 → L4T Loader → ATF → U-Boot → noyau → initramfs → rootfs |
| Base de compatibilité matérielle | Switchroot (L4T BSP, noyau 4.9.140, ATF, U-Boot) |

> ## ⚠️ État réel du projet
>
> **Ce dépôt contient la base technique, pas une distribution installable.**
>
> - Aucun binaire Switchroot (noyau, DTB, modules, firmware, ATF/U-Boot) n'est versionné ici : ces composants doivent être récupérés depuis les sources officielles Switchroot, dont les licences et la provenance sont documentées dans [`THIRD-PARTY.md`](THIRD-PARTY.md) et [`switchroot/README.md`](switchroot/README.md).
> - Aucun test sur console réelle n'a été effectué pour cette version. Toutes les étapes marquées « à tester » dans [`docs/05-status-matrix.md`](docs/05-status-matrix.md) le sont réellement.
> - Un point bloquant structurel est identifié et documenté : **systemd (Arch Linux ARM) ne peut pas démarrer sur le noyau L4T 4.9.140** de Switchroot (systemd exige ≥ 4.15 et cgroup v2). Voir [`docs/06-known-limitations.md`](docs/06-known-limitations.md) et l'ADR [`docs/adr/0004-systemd-kernel-compatibility.md`](docs/adr/0004-systemd-kernel-compatibility.md).
>
> La version `0.1.0` est publiée en **pre-release** : elle sert de socle de développement reproductible.

## Téléchargement

Les archives de développement sont publiées dans les [Releases](https://github.com/ClmentCch/OmarchySwitch/releases).
La base `v0.1.0` est produite par `make package` et contient l'arborescence complète sous `omarchyswitch/`.

## Ce que fait ce dépôt

1. **Définit l'architecture** de la distribution : couches, chaîne de démarrage, décisions techniques (ADR).
2. **Prépare Arch Linux ARM64** : profil de bootstrap, `pacman.conf` aarch64, overlay rootfs, unités systemd, paquets Arch (`PKGBUILD`).
3. **Encadre l'intégration Switchroot** : emplacements dédiés, manifeste de provenance, script d'intégration avec vérification d'empreintes.
4. **Adapte Omarchy** : récupération du tag `v4.5.0` épinglé, configuration Hyprland/Waybar/uwsm adaptée à un écran 720p tactile, script d'application idempotent.
5. **Documente le matériel Tegra X1** composant par composant (GPU, audio, Joy-Con, Wi-Fi, Bluetooth, tactile, stockage, énergie) avec l'état réel de chaque pilote.
6. **Fournit l'outillage** : bootstrap, construction de rootfs, génération d'image SD, packaging, validation d'architecture, CI GitHub Actions.
7. **Reste honnête** : rien n'est présenté comme fonctionnel sans test, aucun pilote n'est inventé, aucun binaire non redistribuable n'est inclus.

## Structure du dépôt

```text
.
├── bootloader/           # hekate : hekate_ipl.ini, entrées L4T, installation des fichiers de boot
├── switchroot/           # emplacements + manifeste des composants Switchroot (noyau, DTB, modules, firmware, pilotes)
├── archlinux/            # bootstrap ALARM, pacman, overlay rootfs, PKGBUILD
├── hardware/             # aarch64-tegra-x1 : état et prérequis par sous-système
├── omarchy/              # upstream épinglé, patches, configs, scripts d'adaptation
├── desktop/              # Hyprland, Waybar, Walker, terminal, thèmes, polices
├── applications/         # portage des outils Switchroot, applications système, guide de portage
├── installer/            # installateur hôte : partitionnement, rootfs, first boot
├── recovery/             # diagnostics et restauration des fichiers de démarrage
├── build/                # scripts de build globaux, configs, manifestes de paquets
├── configs/              # configuration centrale + versions épinglées (versions.lock)
├── scripts/              # scripts demandés : bootstrap, rootfs, intégrations, validation, image, release
├── docs/                 # architecture, chaîne de boot, build, limites connues, ADR, recherche
├── .github/workflows/    # CI : validation, packaging, bootstrap ARM64 manuel
├── Makefile              # raccourcis : validate, package, image, clean
├── VERSION               # 0.1.0
└── THIRD-PARTY.md        # licences et provenance de tous les composants upstream
```

## Démarrage rapide (hôte Linux, aarch64 ou x86_64 avec outils croisés)

```bash
# 1. Vérifier la cohérence du dépôt (ne nécessite ni root ni réseau)
./scripts/validate-architecture.sh

# 2. Voir la configuration effective
make config

# 3. Préparer les sources upstream épinglées (Omarchy v4.5.0, hekate v6.5.4)
./build/scripts/fetch-upstreams.sh

# 4. Construire un rootfs Arch Linux ARM64 (root requis, réseau requis)
sudo ./scripts/build-rootfs.sh --output ./build/output/rootfs

# 5. Intégrer les composants Switchroot (nécessite les fichiers récupérés à la main)
sudo ./scripts/integrate-switchroot.sh --rootfs ./build/output/rootfs

# 6. Intégrer Omarchy (paquets aarch64 + configurations)
sudo ./scripts/integrate-omarchy.sh --rootfs ./build/output/rootfs

# 7. Générer une image SD (GPT : FAT32 boot + ext4 root)
sudo ./scripts/build-image.sh --rootfs ./build/output/rootfs --output ./build/output/omarchyswitch.img

# 8. Publier l'archive de base
./scripts/package-release.sh
```

Chaque script accepte `--help`, refuse de s'exécuter avec une architecture non-aarch64 pour les étapes de construction, et n'écrit jamais sur un périphérique bloc sans confirmation explicite.

## Ce qui doit encore être fait à la main

La liste exhaustive, fichier par fichier, se trouve dans [`docs/09-remaining-work.md`](docs/09-remaining-work.md). En résumé :

| À fournir | Où | Pourquoi |
|---|---|---|
| Noyau Switchroot (`uImage`) | `switchroot/kernel/` | Aucun noyau Tegra X1 avec support écran/batterie n'est redistribuable depuis ce dépôt |
| DTBs Tegra 210 Switch (`nx-plat.dtimg`) | `switchroot/dtb/` | Spécifiques au matériel, licence NVIDIA |
| Modules noyau + firmware BSP | `switchroot/modules/`, `switchroot/firmware/` | Doivent correspondre exactement au noyau utilisé |
| ATF + U-Boot (`bl31.bin`, `bl33.bin`) | `switchroot/boot/` | Fournis par le bootstack Switchroot, non redistribués ici |
| Empreintes SHA-256 | `switchroot/manifest.toml` | Le script d'intégration refuse tout fichier non vérifié par défaut |
| Décision sur le couple noyau/systemd | `docs/adr/0004-systemd-kernel-compatibility.md` | Bloque l'utilisateur final Arch + Omarchy |
| Tests sur console | `docs/10-testing.md` | Aucun matériel accessible depuis l'environnement de développement |

## Licence

Le code et la documentation propres à OmarchySwitch sont sous licence **MIT** — voir [`LICENSE`](LICENSE).
Les composants upstream conservent leurs licences respectives (Omarchy MIT, noyau Linux GPL-2.0, hekate GPL-2.0, ATF BSD-3-Clause, U-Boot GPL-2.0+, composants NVIDIA propriétaires) : voir [`THIRD-PARTY.md`](THIRD-PARTY.md).
