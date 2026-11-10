# Polices sur Switch

## Besoin

- une police monospace lisible à 720p pour le terminal et l'éditeur ;
- une police d'interface couvrant le français (accents) ;
- des icônes pour Waybar (Nerd Font ou équivalent fourni par le thème).

## Choix par défaut

| Rôle | Paquet | Remarque |
|---|---|---|
| Monospace | `ttf-jetbrains-mono` | disponible dans `extra` |
| Interface | `noto-fonts` | couverture large, accents garantis |
| Emoji | `noto-fonts-emoji` | nécessaire à certains modules Waybar |
| Icônes barre | police Nerd Font du thème Omarchy | si absente, Waybar affiche des carrés |

`configs/omarchyswitch.conf` définit `DESKTOP_FONT_PACKAGE` ; la liste réellement
installée est [`packages.txt`](packages.txt).

## Vérifier la disponibilité aarch64

Avant de construire, contrôler que les paquets existent sur le miroir ARM :

```bash
# depuis le rootfs, pendant le build
pacman -Si ttf-jetbrains-mono
```

Un paquet absent fait échouer `pacman -S` : c'est volontaire, mieux vaut un
échec explicite qu'un système sans police lisible.

## Rendu à l'échelle 1

À 1280×720 avec `GDK_SCALE=1`, une police de 11–12 px est lisible ; 9 px ne
l'est pas. Ne pas compenser par un scaling fractionnaire : le GPU et la dalle ne
le justifient pas.
