# `omarchy/patches/` — patches à appliquer à Omarchy

## État actuel : aucun patch

La base 0.1.0 ne modifie pas le code d'Omarchy. Toutes les adaptations sont
faites par **surcharge de configuration** (`omarchy/configs/`), ce qui :

- évite de maintenir un fork ;
- survit aux mises à jour d'Omarchy ;
- reste lisible et réversible.

## Quand un patch devient nécessaire

Un patch n'est justifié que si la configuration ne suffit pas, par exemple :

| Cas | Configuration suffisante ? |
|---|---|
| Écran 720p, rotation, échelle | **oui** (Hyprland le permet) |
| Désactiver le scaling fractionnaire | **oui** |
| Remplacer un raccourci clavier | **oui** |
| Changer le terminal par défaut | **oui** |
| Contourner un chemin PC codé en dur dans un script Omarchy | non → patch |
| Adapter les mises à jour au noyau Tegra | non → patch |

## Format obligatoire

- Nom : `NNNN-sujet-court.patch`, numérotation à quatre chiffres.
- En-tête `From`, `Date`, `Subject: [PATCH] ...`, corps expliquant le problème
  et la solution, puis `---` et le diff.
- Un patch = un sujet. Pas de patch fourre-tout.
- Le fichier `series` liste les patches dans l'ordre d'application.
- Chaque patch ajouté doit être mentionné dans `docs/05-status-matrix.md` avec
  son état (testé / non testé).

## Application

```bash
# Depuis une copie de travail d'Omarchy au tag épinglé
cd build/src/omarchy
while read -r p; do
  [[ -z "$p" || "$p" == \#* ]] && continue
  patch -Np1 -i "../../../omarchy/patches/$p"
done < ../../../omarchy/patches/series
```

Le script `scripts/integrate-omarchy.sh` n'applique **pas** ces patches : les
paquets installés proviennent du dépôt Omarchy. Un patch implique donc de
reconstruire les paquets concernés, ce qui n'est pas dans le périmètre de la
version 0.1.0.

## Contenu actuel

`series` ne contient aucune entrée, volontairement. Le fichier existe pour que
l'emplacement et le format soient définis avant le premier patch, pas après.
