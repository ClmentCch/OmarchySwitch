# `switchroot/scripts/`

## `import-components.sh`

Copie les composants Switchroot dans les emplacements attendus et mesure leurs
empreintes.

```bash
# Importer depuis un dossier déjà extrait
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted

# Importer depuis les dossiers du dépôt (après copie manuelle)
./switchroot/scripts/import-components.sh --from switchroot

# Vérifier ce qui manque
./switchroot/scripts/import-components.sh --list-missing

# Simuler
./switchroot/scripts/import-components.sh --from /srv/extracted --dry-run
```

Disposition reconnue sous `--from` :

```text
<from>/kernel/uImage
<from>/dtb/nx-plat.dtimg
<from>/boot/initramfs, boot.scr, bl31.bin, bl33.bin
<from>/modules/<version>/...
<from>/firmware/...
```

ou les mêmes fichiers à plat (`<from>/uImage`, ...).

Ce qu'il produit :

- `switchroot/{kernel,dtb,boot,modules,firmware}/` peuplés ;
- `switchroot/manifest.local.toml` avec les SHA-256 (fichiers et arborescences),
  **ignoré par Git** ;
- un code de sortie non nul si un composant déclaré est introuvable.

## Pourquoi les empreintes sont dans un fichier séparé

`switchroot/manifest.toml` décrit **ce qui est requis** et ne contient aucune
empreinte : il est versionné et lisible. Les empreintes dépendent de vos
fichiers, donc de votre console et de votre build ; elles restent locales. Le
script d'intégration fusionne les deux, les valeurs locales gagnant.

## Règle

Ne jamais commiter `manifest.local.toml` : il révèle la composition exacte de
votre installation, et les binaires associés ne sont pas redistribuables.
