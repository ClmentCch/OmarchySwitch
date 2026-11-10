# Notes de recherche

Ces notes documentent ce qui a été vérifié dans les sources upstream avant
d'écrire le code. Elles ne sont pas de la documentation utilisateur : elles
servent à justifier les décisions et à éviter de refaire la recherche.

| Note | Sujet |
|---|---|
| [`omarchy-4.5.0.md`](omarchy-4.5.0.md) | Ce qu'Omarchy 4.5.0 fournit, ce qui est réutilisable, ce qui est écarté |
| [`switchroot-erista.md`](switchroot-erista.md) | Composants Switchroot, chaîne de boot, contraintes matérielles |

## Méthode

1. Lire la source officielle (dépôt, README, documentation du projet).
2. Vérifier la disponibilité réelle (HTTP 200 sur un paquet, un tag, une release).
3. Noter la date de vérification.
4. Écrire ce qui est **certain**, séparément de ce qui est **rapporté par des
   tiers**.

Les affirmations de tiers (blogs, projets expérimentaux) sont marquées comme
telles : elles ne sont pas des garanties.
