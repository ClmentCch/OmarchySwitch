# Walker sur Switch

Walker est le lanceur d'applications d'Omarchy. Il est particulièrement utile
sur la console, où les raccourcis clavier ne sont pas découvrables au doigt.

## État

- Paquet installé par `install-desktop.sh` (via `build/manifests/desktop-packages.txt`).
- Configuration : celle d'Omarchy, non remplacée.
- **Aucun test tactile** n'a été effectué.

## Points d'attention sur console

| Sujet | Recommandation |
|---|---|
| Ouverture sans clavier | prévoir un bouton Waybar (`on-click`) lançant `walker` |
| Taille de police | augmenter pour rester lisible à 720p (le thème Omarchy est prévu pour du 1080p+) |
| Clavier tactile | `wvkbd` ou `squeekboard` si une saisie est nécessaire ; non installé par défaut |
| Lancement au clic | vérifier que le thème ne dépend pas d'un survol souris |

## Vérification

```bash
walker --version
walker                 # doit ouvrir la fenêtre du lanceur
```

Si Walker ne s'ouvre pas, vérifier d'abord que la session Hyprland tourne :
Walker est un client Wayland et échoue sans compositeur.

## Ce qui n'est pas fait

Aucune intégration tactile spécifique n'est fournie dans la base 0.1.0. C'est un
choix : mieux vaut livrer un lanceur qui fonctionne au clavier USB que promettre
une expérience tactile non testée.
