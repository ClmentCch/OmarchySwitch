# Thèmes sur Switch

## Principe

Les thèmes Omarchy sont fournis par les paquets et appliqués par la CLI
`omarchy`. Ce projet **ne crée pas de thème** et **ne copie pas** les thèmes
upstream : il documente les contraintes propres à la console.

## Ce qu'un thème modifie

| Élément | Impact sur la console |
|---|---|
| Fonds d'écran | poids et résolution : préférer 1280×720 natif |
| Couleurs Waybar/Hyprland | aucun coût |
| Polices | lisibilité à 720p |
| Animations d'intro | coût GPU et allongement du login |

Les thèmes Omarchy 4.5 peuvent jouer une courte intro silencieuse au login ;
cela se désactive dans *Appearance → Animations*. Sur Switch, la désactiver est
raisonnable (temps de login et batterie).

## Appliquer un thème

```bash
omarchy-theme-set <nom>     # nom exact fourni par Omarchy
```

La commande est fournie par le paquet `omarchy` ; elle n'est pas réimplémentée
ici.

## Créer un thème spécifique Switch

Si un thème dédié devient nécessaire :

1. partir d'un thème existant dans `~/.config/omarchy/themes/` ;
2. ne changer que les couleurs et les fonds (pas la structure) ;
3. placer le résultat dans `~/.config/omarchy/themes/omarchyswitch/` ;
4. documenter ici ce qui diffère, et pourquoi.

Ne pas versionner les images de fond dans ce dépôt : elles appartiennent à une
Release ou au thème upstream (voir `.gitignore` et `THIRD-PARTY.md`).

## État

Aucun thème n'a été testé sur la console.
