# Applications Switchroot — analyse et statut

Ces outils viennent de l'écosystème Switchroot (Ubuntu Bionic/Jammy). Ils ne
sont **pas installés** par OmarchySwitch : chacun est analysé, puis marqué
`porte`, `a_porter`, `bloque` ou `remplace` dans
[`manifest.toml`](manifest.toml).

## Pourquoi une analyse plutôt qu'une installation

Les paquets Switchroot sont liés à :

- `glibc` d'Ubuntu 18.04/20.04, plus ancienne que celle d'Arch ;
- des bibliothèques NVIDIA du BSP dans des chemins Ubuntu ;
- des services `systemd` Ubuntu ;
- parfois un noyau patché spécifique.

Les installer tels quels sur Arch ARM produit au mieux une erreur de dépendance,
au pire un binaire qui s'exécute mal. La démarche correcte est : identifier la
fonction, trouver l'équivalent Arch, ou recompiler.

## Remplacements déjà identifiés

| Outil Switchroot | Équivalent Arch / OmarchySwitch | Statut |
|---|---|---|
| Scripts de configuration réseau | NetworkManager (+ `nmcli`) | remplace |
| Réglage de luminosité | `brightnessctl` | remplace |
| Test d'entrées | `evtest`, `libinput` | remplace |
| Monitoring batterie | `upower`, `/sys/class/power_supply` | remplace |
| L4T-Megascript | installation manuelle documentée | a_porter |
| `joycond` | paquet Arch ou compilation | a_porter |
| `nvpmodel` | non remplacé | bloque |

## Voir aussi

- [`../PORTING.md`](../PORTING.md) — méthode de portage
- [`../../docs/05-status-matrix.md`](../../docs/05-status-matrix.md) — état global
- [`../../THIRD-PARTY.md`](../../THIRD-PARTY.md) — licences
