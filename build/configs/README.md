# `build/configs/` — configuration de construction

| Fichier | Consommé par | Rôle |
|---|---|---|
| `ci.env` | `.github/workflows/build.yml` | Taille d'image, jobs parallèles, timeout de bootstrap |

La configuration du projet elle-même reste dans `configs/omarchyswitch.conf`.
Ce dossier ne contient que ce qui est propre à la construction automatisée : ne
pas y dupliquer des valeurs de distribution.

## Format

`ci.env` est un fichier `KEY=value` sans `export`, lu par GitHub Actions via
`$GITHUB_ENV` après filtrage. Il ne doit contenir **aucun secret** : les
secrets GitHub ne transitent jamais par un fichier versionné.

## Modifier une valeur

1. éditer `ci.env` ;
2. vérifier que le workflow la référence ;
3. lancer la validation : `./scripts/validate-architecture.sh`.

Une variable inutilisée dans `ci.env` est un piège : elle donne l'illusion d'un
réglage actif. La validation signale les fichiers vides, pas les variables
mortes ; en ajoutant une variable, ajouter son usage dans le même commit.
