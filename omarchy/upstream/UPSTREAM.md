# Omarchy upstream — références épinglées

| Élément | Valeur |
|---|---|
| Dépôt | <https://github.com/omacom/omarchy> |
| Tag | `v4.5.0` |
| Date de release | 2026-11-04 |
| Licence | MIT (`LICENSE` du dépôt) |
| Paquets aarch64 | `https://pkgs.omarchy.org/stable/aarch64/` (canal `edge` également publié) |
| ISO ARM64 | `https://iso.omarchy.org/omarchy-4.5.0-aarch64.iso` — **non utilisée** |
| Documentation | <https://omarchy.org/manual/>, source dans `manual/` du dépôt |

Ces valeurs sont dupliquées dans [`../../configs/versions.lock`](../../configs/versions.lock)
et vérifiées par `scripts/validate-architecture.sh`.

## Structure du dépôt upstream (utile pour l'adaptation)

```text
omarchy/
├── applications/     # définitions d'applications installables
├── bin/              # CLI `omarchy`
├── config/           # configurations livrées (~/.config/...)
├── default/          # valeurs par défaut
├── docs/             # documentation développeur
├── etc/              # fichiers système (/etc)
├── install/          # scripts d'installation
├── manual/           # manuel utilisateur (source du site)
├── migrations/       # migrations de configuration entre versions
├── scripts/          # scripts internes (thèmes, mises à jour, ...)
├── shell/            # intégration shell
├── themes/           # thèmes
└── version           # version courante
```

## Ce que ce projet utilise réellement

| Élément upstream | Usage dans OmarchySwitch |
|---|---|
| Paquets `omarchy`, `omarchy-settings` (aarch64) | installés par `scripts/integrate-omarchy.sh` |
| `config/` (conventions de chemins) | référencé, pas copié |
| `manual/31-dotfiles.md`, `manual/33-monitors.md`, `manual/43-making-your-own-theme.md` | source de vérité pour les surcharges |
| `themes/` | installés par les paquets |

## Ce que ce projet n'utilise pas

- `install/` : conçu pour une installation Arch complète sur PC, avec
  partitionnement, Limine, noyau Omarchy et services PC.
- `linux-omarchy` : noyau ARM pour machines NVIDIA, sans support Tegra X1.
- `migrations/` : inutile sur une installation neuve.

## Vérifier l'upstream avant une release

```bash
./build/scripts/fetch-upstreams.sh --check    # le tag existe-t-il encore ?
./build/scripts/fetch-upstreams.sh            # clone superficiel dans build/src/omarchy
```

Si le tag `v4.5.0` disparaît ou si les paquets aarch64 changent de canal,
mettre à jour `configs/versions.lock`, ce fichier et `CHANGELOG.md` ensemble.

## Licence et attribution

Omarchy est sous MIT. Les configurations dérivées de ce projet restent sous MIT
(voir `LICENSE`). L'attribution à Omarchy est conservée dans la documentation et
dans les fichiers de configuration qui reprennent ses conventions.
