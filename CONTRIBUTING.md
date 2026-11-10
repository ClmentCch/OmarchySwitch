# Contribuer à OmarchySwitch

Merci de contribuer. Ce projet touche à un bootloader, à un noyau et à des
partitions de stockage : une erreur peut rendre une console inutilisable.
Les règles ci-dessous existent pour cette raison.

## Règles de base

1. **Architecture cible : `aarch64` uniquement.** Toute contribution qui
   introduit un paquet, un binaire ou un chemin `x86_64`/`amd64`/`i686` est
   refusée. `./scripts/validate-architecture.sh` échoue dans ce cas.
2. **Aucun binaire non redistribuable.** Noyau Switchroot, DTB, modules,
   firmware, ATF, U-Boot et composants NVIDIA ne sont pas versionnés ici.
   Fournissez des scripts, des manifestes et des empreintes, pas des blobs.
3. **Aucune affirmation non testée.** Si vous n'avez pas démarré la console,
   écrivez « à tester ». Une fonctionnalité non vérifiée reste marquée
   `a_tester` dans `hardware/aarch64-tegra-x1/features.toml`.
4. **Pas de secrets.** Clés, jetons, mots de passe Wi-Fi et identifiants
   personnels n'ont leur place ni dans le dépôt, ni dans un manifeste, ni dans
   une documentation. La validation recherche ces motifs.
5. **Documentez la provenance.** Tout composant upstream ajouté doit avoir son
   entrée dans `THIRD-PARTY.md` et, si c'est un fichier matériel, dans
   `switchroot/manifest.toml` avec licence et empreinte.

## Vérifications avant une pull request

```bash
./scripts/validate-architecture.sh      # obligatoire, sans root
bash -n scripts/*.sh scripts/lib/*.sh   # inclus dans la validation
make package                            # vérifie que l'archive se construit
```

La CI (`.github/workflows/build.yml`) exécute la validation sur chaque push et
chaque pull request. Une PR qui casse la validation n'est pas fusionnée.

## Conventions

- **Shell** : `#!/usr/bin/env bash`, `set -euo pipefail`, `shellcheck` propre,
  guillemets autour des variables, `--help` sur chaque script public.
- **Documentation** : français, sauf les commentaires de code et les messages
  de script (anglais), afin que les contributions upstream restent lisibles.
- **Configuration** : commentaires en anglais, valeurs par défaut commentées,
  surcharge locale via `configs/local.conf` (non versionné).
- **Commits** : impératif présent, une intention par commit, référence à l'ADR
  ou au fichier concerné quand c'est utile.

## Signaler un problème matériel

Joignez la sortie de :

```bash
./recovery/diagnostics/collect.sh --sd /run/media/$USER/OMARCHYS
```

Elle rassemble la configuration hekate, les empreintes des fichiers de boot et
les journaux pertinents, sans donnée personnelle.

## Licence des contributions

En proposant une pull request, vous acceptez que votre contribution soit
publiée sous la licence MIT du projet (voir `LICENSE`). Les composants
upstream que vous référencez conservent leur licence.
