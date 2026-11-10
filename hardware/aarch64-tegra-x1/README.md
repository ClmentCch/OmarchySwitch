# `hardware/aarch64-tegra-x1/` — couche matérielle

Tout ce qui concerne le SoC Tegra X1 (T210) d'une Switch V1, sous-système par
sous-système : ce qui fonctionne, ce qui dépend de quel composant, et ce qui
reste bloqué.

## Fiche matérielle

| Élément | Valeur |
|---|---|
| Modèle | HAC-001 (2017), révision « Erista » |
| SoC | NVIDIA Tegra X1 (ODNX02-A2), 4× A57 + 4× A53, ARMv8-A |
| GPU | GM20B (Maxwell), 256 cœurs |
| RAM | 4 Gio LPDDR4 (partagés avec le GPU) |
| Écran | Dalle DSI 720×1280 (JDI LPM062M326A), montée en portrait, rotation logicielle |
| Stockage | microSD (boot Linux) + eMMC 32 Gio (Horizon OS, non utilisé ici) |
| Réseau | Wi-Fi Broadcom BCM4356 (PCIe), Bluetooth 4.1 (UART) |
| Entrées | Tactile `stmfts` (I²C), Joy-Con (rails + Bluetooth), boutons side-band |
| Énergie | PMIC MAX77620 + MAX77621, fuel gauge MAX17050 |
| Démarrage | RCM (CVE-2018-6242) → hekate ; **Erista uniquement** |

## Sous-systèmes

| Dossier | Sujet | Statut de la base 0.1.0 |
|---|---|---|
| [`display/`](display/README.md) | Dalle DSI, rétroéclairage, HDMI/dock | prépa |
| [`gpu/`](gpu/README.md) | GM20B, pilote NVIDIA, Mesa | prépa |
| [`audio/`](audio/README.md) | Haut-parleurs, casque, micro | prépa |
| [`joycon/`](joycon/README.md) | Joy-Con attachés et Bluetooth | prépa |
| [`wifi/`](wifi/README.md) | BCM4356, firmware, NVRAM | prépa |
| [`bluetooth/`](bluetooth/README.md) | BCM2076, firmware `.hcd` | prépa |
| [`touchscreen/`](touchscreen/README.md) | `stmfts`, calibration | prépa |
| [`storage/`](storage/README.md) | SD, eMMC, montages, options ext4 | prépa |
| [`power/`](power/README.md) | Batterie, charge, veille, thermique | prépa |

« prépa » signifie : les fichiers, la configuration et la documentation existent,
mais **rien n'a été exécuté sur une console**. Voir
[`../../docs/05-status-matrix.md`](../../docs/05-status-matrix.md).

## Source de vérité machine

[`features.toml`](features.toml) décrit chaque fonctionnalité avec un statut
normalisé (`fonctionnel`, `prepare`, `bloque`, `a_tester`, `non_supporte`) et
son point de blocage. `scripts/validate-architecture.sh` vérifie que ce fichier
reste valide et que les statuts appartiennent à cette liste.

## Règle du projet

Aucun pilote n'est écrit ni inventé ici. Les pilotes viennent du noyau
Switchroot (4.9.140, blobs NVIDIA) ou, pour la suite, du noyau mainline avec les
patches Tegra. Ce dossier décrit l'existant et prépare l'intégration ; il ne
prétend pas remplacer Switchroot.
