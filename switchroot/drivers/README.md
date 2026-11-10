# `switchroot/drivers/` — pilotes spécifiques et patches de référence

Ce dossier ne contient **aucun pilote écrit pour ce projet** : il documente les
pilotes existants, leur emplacement upstream et leur état de support sur
Erista. Il sert de point de référence pour le jour où un pilote devra être
porté sur un noyau plus récent.

## Pilotes utilisés par la base 0.1.0 (noyau L4T 4.9.140)

| Sous-système | Pilote / module | Source upstream | État |
|---|---|---|---|
| Écran DSI | pilote panneau JDI (intégré au noyau L4T) | BSP NVIDIA + Switchroot | Fourni par le noyau |
| GPU | `nvgpu` (blob NVIDIA) | BSP L4T | Fourni par le noyau |
| Audio | `snd_soc_tegra210_*` | noyau L4T | Fourni par le noyau |
| Joy-Con | driver HID Switchroot | noyau L4T | Fourni par le noyau |
| Wi-Fi | `brcmfmac` + firmware BCM4356 | noyau + BSP | Fourni par le noyau/firmware |
| Bluetooth | `hci_uart` + `btbcm` | noyau | Fourni par le noyau/firmware |
| Tactile | `stmfts` | noyau | Fourni par le noyau |
| Stockage | `sdhci_tegra` | noyau | Fourni par le noyau |
| Énergie | `max77620`, `tegra_soctherm` | noyau | Fourni par le noyau |

Aucun de ces pilotes n'est modifié par OmarchySwitch.

## Patches de référence pour un noyau mainline (phase ultérieure)

Le projet [`alarm-tegra-x1`](https://notdouble.com/p/alarm-tegra-x1) documente
un bring-up mainline sur HAC-001 et publie des patches utiles ; le projet
Switchroot `mainline-kernel` existe également
(<https://gitlab.com/switchroot/kernel/mainline-kernel>, branche `switch-dev`).
Les thèmes connus à traiter, si ce chemin est choisi :

| Sujet | Référence |
|---|---|
| Panneau JDI LPM062M326A (DSI) | patch de pilote DRM panel (dérivé Switchroot) |
| Tactile `stmfts` | activation des IRQ + alimentation permanente du contrôleur |
| Joy-Con | rails + driver HID |
| USB gadget (XUSB) | `dma_alloc_coherent`, `CONFIG_USB_ACM=y` |
| PCIe du Wi-Fi | alim `ldo1` MAX77620, sinon SError |
| Redémarrage après panic | priorité du handler PMC devant PSCI |
| Framebuffer console | non supporté par DRM Tegra (pas de fbdev GEM-DMA) |

Ces éléments sont des **pistes documentées par des tiers**, pas des patches
intégrés : ils ne sont ni testés ni garantis ici.

## Ce que ce dossier doit contenir plus tard

- `patches/<n>-<sujet>.patch` : patches vérifiés, avec en-tête `From`,
  `Subject`, `---` et mention de la source.
- `series` : ordre d'application.
- `README.md` mis à jour avec l'état réel de chaque patch (testé / non testé).

## Règle du projet

Ne jamais ajouter ici un fichier présenté comme un pilote fonctionnel sans
l'avoir compilé et testé sur la console. Un pilote inventé coûte des heures de
diagnostic à l'utilisateur suivant.
