# Recherche — Omarchy 4.5.0

Vérifié le **2026-11-10**.

## Sources

| Source | URL | Ce qui en a été tiré |
|---|---|---|
| Dépôt | <https://github.com/omacom/omarchy> | Structure, licence MIT, `manual/` |
| Release | <https://github.com/omacom/omarchy/releases/tag/v4.5.0> | Tag `v4.5.0`, publié le 2026-11-04 |
| Site | <https://omarchy.org/> | ISO x86 et aarch64, note « ARM64 preliminary support » |
| Dépôt de paquets | <https://pkgs.omarchy.org/stable/aarch64/> | Paquets aarch64 publiés |
| Annonce | <https://omarchy.org/news/2026/11/omarchy-4-5/> | Premier ISO ARM, cibles NVIDIA ARM |

## Faits vérifiés

- **Licence MIT**, confirmée dans le `README.md` upstream.
- **Structure du dépôt** (lecture de l'arborescence) :
  `applications/`, `bin/`, `config/`, `default/`, `docs/`, `etc/`,
  `install/`, `manual/`, `migrations/`, `scripts/`, `shell/`, `themes/`,
  `version`.
- **Paquets aarch64 réellement publiés** :
  `https://pkgs.omarchy.org/stable/aarch64/omarchy-4.5.0-3-aarch64.pkg.tar.zst`
  répond en HTTP 200 (81 Mio téléchargés pour inspection).
- **ISO ARM64 accessible** : `https://iso.omarchy.org/omarchy-4.5.0-aarch64.iso`
  (HTTP 200).
- **Cibles ARM annoncées** : DGX Spark et machines NVIDIA N1X. Aucune mention
  de Tegra X1.
- **Le noyau Omarchy** (`linux-omarchy`) est un noyau ARM pour ces machines ; il
  n'a pas de support Tegra X1.

## Ce qui est réutilisable

| Élément | Réutilisation |
|---|---|
| Paquets `omarchy` (aarch64) | Installés via le dépôt Omarchy |
| Conventions de configuration (`~/.config`, thèmes) | Respectées, non remplacées |
| `uwsm` + Hyprland | Conservés |
| Manuel (`manual/`) | Référence pour les surcharges |

## Ce qui n'est pas réutilisable

| Élément | Raison |
|---|---|
| ISO aarch64 | Chargeur Limine, noyau `linux-omarchy`, partitionnement PC |
| `install/` | Suppose une installation Arch complète sur PC |
| `linux-omarchy` | Aucun support Tegra X1 ; remplacerait le noyau Switchroot |
| Applications commerciales ARM | Disponibilité et licences non vérifiées |

## Décision qui en découle

Installer les **paquets** Omarchy et surcharger la configuration, plutôt que
copier l'ISO. Voir [`../adr/0001-arch-linux-arm-base.md`](../adr/0001-arch-linux-arm-base.md)
et [`../../omarchy/README.md`](../../omarchy/README.md).

## Incertitudes restantes

- Le paquet `omarchy` dépend-il d'un noyau spécifique ou de `linux-omarchy` ?
  À vérifier avec `pacman -Si omarchy` dans un rootfs aarch64.
- Les paquets aarch64 couvrent-ils la totalité des applications Omarchy ou
  seulement le socle ? À mesurer à l'installation.
- Le comportement d'`uwsm` sans systemd fonctionnel (état actuel : systemd ne
  démarre pas) n'est pas testé.
