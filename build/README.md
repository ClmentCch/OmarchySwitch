# `build/` — outillage de construction

| Chemin | Rôle |
|---|---|
| `scripts/fetch-upstreams.sh` | Clone les sources épinglées (Omarchy, hekate, optionnellement Switchroot) |
| `scripts/build-all.sh` | Exécute tout le pipeline (validation → bootstrap → rootfs → Switchroot → Omarchy → bureau → image → archive) |
| `configs/ci.env` | Variables consommées par GitHub Actions |
| `manifests/` | Listes de paquets et contenu attendu de la partition de boot |

## Sorties

```text
build/
├── cache/          tarball Arch Linux ARM téléchargé (ignoré par Git)
├── src/            clones upstream (ignoré par Git)
└── output/
    ├── rootfs/     rootfs construit
    ├── boot/       arbre de la partition FAT (bootloader/, switchroot/)
    ├── logs/       journaux horodatés de chaque exécution
    └── *.img       images produites
```

Tout `build/output/` et `build/cache/` est ignoré par Git : ce sont des
artefacts, jamais des sources.

## Pipeline

```bash
# Tout, en une commande (root + réseau)
./build/scripts/build-all.sh

# Ou étape par étape, en contrôlant chaque sortie
./scripts/validate-architecture.sh
./scripts/bootstrap-arch.sh
sudo ./scripts/build-rootfs.sh --output build/output/rootfs
sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs
sudo ./scripts/integrate-omarchy.sh --rootfs build/output/rootfs
sudo ./scripts/install-desktop.sh --rootfs build/output/rootfs
sudo ./scripts/build-image.sh --rootfs build/output/rootfs --output build/output/omarchyswitch.img
./scripts/package-release.sh
```

## Ce que la CI peut faire

| Job | Ce qu'il fait | Limite |
|---|---|---|
| `validate` | validation statique complète | ne prouve pas que l'image démarre |
| `package` | construit et vérifie l'archive ZIP | pas de binaires matériels inclus |
| `rootfs-arm64` | bootstrap du rootfs sur runner ARM64 (manuel) | pas d'Omarchy ni de Switchroot sans réseau/credentials ; ne produit pas d'image |

Aucun job ne produit une image Switch « fonctionnelle » : les composants
matériels ne sont pas disponibles dans un runner et ne sont pas redistribuables.

## Reproductibilité

- Versions upstream épinglées dans `configs/versions.lock`.
- Tarball Arch Linux ARM vérifié par SHA-256 (épinglage local obligatoire).
- Aucun téléchargement implicite : chaque script dit ce qu'il télécharge.
- L'archive de release enregistre le commit HEAD dans `BUILD-COMMIT`.
