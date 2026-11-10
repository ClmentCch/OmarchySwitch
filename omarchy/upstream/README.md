# `omarchy/upstream/`

Ce dossier ne contient **aucun code Omarchy** : il documente la version amont
utilisée et la manière de la récupérer.

| Fichier | Contenu |
|---|---|
| `UPSTREAM.md` | version épinglée, licence, sources, procédure de mise à jour |

## Règles

1. **Aucun fichier upstream n'est copié ici.** Omarchy est installé par ses
   paquets aarch64 (`pkgs.omarchy.org`), pas par copie de dépôt.
2. La version est épinglée dans `configs/versions.lock` et
   `configs/omarchyswitch.conf` ; le validateur vérifie qu'elles concordent.
3. Toute modification du comportement Omarchy passe par
   `omarchy/patches/` ou `omarchy/configs/`, jamais par une réécriture silencieuse
   du code amont.
4. Une mise à jour d'Omarchy se fait dans un commit dédié, avec la date et la
   raison dans `CHANGELOG.md`.

## Vérifier la version installée

```bash
pacman -Q omarchy            # paquet amont
cat /usr/share/omarchy/version 2>/dev/null || true
```

## Voir aussi

- [`UPSTREAM.md`](UPSTREAM.md) — détails et procédure
- [`../README.md`](../README.md) — stratégie d'intégration
- [`../../docs/research/omarchy-4.5.0.md`](../../docs/research/omarchy-4.5.0.md) — ce qui a été vérifié
