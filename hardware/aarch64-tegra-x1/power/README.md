# Énergie — batterie, charge, veille, thermique

## Matériel

| Élément | Détail |
|---|---|
| PMIC | MAX77620 (rails principaux) + MAX77621 (CPU/GPU) |
| Fuel gauge | MAX17050 (capacité, tension, courant) |
| Chargeur | BQ24193 (charge, limite de courant) |
| Thermique | capteurs Tegra (`tegra_soctherm`, BPMP) |
| Veille | LP0 (suspend to RAM) |

## Ce que gère le noyau Switchroot

- lecture de la batterie via `max17050` ;
- charge et limites via `bq24193` ;
- régulation thermique et fréquence via `tegra_soctherm` / BPMP ;
- profils de performance via `nvpmodel` (fichier
  `/etc/nvpmodel/nvpmodel_t210.conf` dans les images Switchroot).

## Ce que gère hekate

- `libsys_lp0.bso` : indispensable à la veille LP0. Sans lui, hekate refuse de
  démarrer L4T (`missing lp0 (sleep) lib`).
- `autohosoff` : extinction automatique au réveil par RTC.

## Veille (suspend)

La veille est le point le plus fragile d'un système Linux sur Switch :

- elle dépend du noyau **et** de la bibliothèque LP0 de hekate ;
- au réveil, plusieurs périphériques (tactile, Joy-Con, audio) peuvent ne pas
  se réinitialiser ;
- Omarchy utilise `hypridle`/`hyprlock` ; la politique de veille doit être
  ajustée pour éviter les réveils en boucle.

Aucun test de veille n'a été effectué dans ce projet. Ne pas promettre une
autonomie ou un comportement de veille tant que ce n'est pas mesuré.

## Batterie : où lire l'état

```bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0   # si upower installé
cat /sys/class/power_supply/*/capacity
cat /sys/class/power_supply/*/status
```

## Profils de performance

Les images Switchroot fournissent `nvpmodel`. Sur OmarchySwitch, la commande
n'est pas installée par défaut : décider d'un profil (batterie vs performance)
est un choix utilisateur, à documenter dans une version ultérieure.

## Clés hekate liées

| Clé | Effet | Utilisée ici |
|---|---|---|
| `autohosoff` | extinction après réveil RTC | oui (`1`) |
| `ram_oc` | overclock RAM | non (risque de corruption) |
| `dvfsb`, `gpu_dvfsc`, `limit_gpu_clk` | DVFS Mariko | non (Erista uniquement) |

## État

**prépa** : aucun relevé de consommation, aucune mesure thermique, aucun test
de veille.
