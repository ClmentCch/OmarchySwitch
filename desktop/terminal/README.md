# Terminal sur Switch

## Choix par défaut : `foot`

| Terminal | Avantages | Inconvénients sur Switch |
|---|---|---|
| `foot` | Wayland natif, très léger, rapide au démarrage | moins de fonctions que Kitty/Ghostty |
| `alacritty` | rapide, populaire, config Omarchy existante | rendu GPU plus coûteux |
| `ghostty` | moderne, rapide | support `aarch64` et Tegra à vérifier |
| `kitty` | riche | lourd pour GM20B |

`foot` est sélectionné via `DESKTOP_TERMINAL_PACKAGE="foot"` dans
`configs/omarchyswitch.conf`. Omarchy utilise son propre choix par défaut ; si
vous préférez le conserver, changez cette variable — rien d'autre n'en dépend.

## Ce qui ne change pas

Les raccourcis Omarchy qui ouvrent un terminal continuent de fonctionner, quel
que soit le terminal choisi : ils reposent sur le nom du binaire déclaré dans la
configuration Omarchy, pas sur une intégration spécifique.

## Réglages pour un écran 720p

- police ≥ 11 pt pour rester lisible ;
- `pad` réduit (bord de fenêtre) pour gagner des colonnes ;
- éviter les effets de transparence (coût GPU inutile).

## Vérification

```bash
foot --version
foot -e echo ok
```

## Non testé

Aucun terminal n'a été lancé sur la console dans le cadre de cette version.
