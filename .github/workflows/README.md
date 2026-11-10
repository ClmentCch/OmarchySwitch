# `.github/workflows/`

| Fichier | Déclencheur | Rôle |
|---|---|---|
| `build.yml` | push, pull request, manuel | Validation statique, packaging de l'archive, bootstrap ARM64 optionnel |

## Jobs

| Job | Runner | Ce qu'il prouve | Ce qu'il ne prouve pas |
|---|---|---|---|
| `validate` | `ubuntu-latest` | structure, syntaxe, cohérence aarch64, manifests, absence de secrets | qu'un système démarre |
| `package` | `ubuntu-latest` | l'archive ZIP se construit et passe ses contrôles | que l'image est bootable |
| `rootfs` (manuel) | `ubuntu-24.04-arm` | le tarball Arch ARM s'extrait et pacman s'initialise sur ARM64 | l'installation des paquets, Omarchy, Switchroot |

## Pourquoi le job `rootfs` est manuel et limité

- Il télécharge ~1 Gio et prend ~20 minutes : inutile à chaque push.
- Il s'arrête à `--stage-only` : installer tous les paquets demanderait des
  minutes supplémentaires et ne validerait toujours pas la console.
- Les composants Switchroot ne sont pas disponibles : aucune image produite par
  la CI ne peut démarrer.

## Ce que la CI ne fera jamais

- Publier une release automatiquement (action humaine délibérée).
- Télécharger des blobs NVIDIA.
- Prétendre qu'une image est fonctionnelle.
- Écrire sur un périphérique bloc.

## Lancer manuellement

```bash
gh workflow run build.yml -f build_rootfs=true
```

## Variables

`build/configs/ci.env` documente les valeurs ; le workflow les duplique en clair
pour rester lisible sans checkout. En cas de changement, mettre à jour les deux
fichiers dans le même commit.
