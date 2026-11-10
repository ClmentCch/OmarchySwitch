# 0004 — Compatibilité systemd / noyau 4.9

- **Statut :** **ouverte — bloquante**
- **Date :** 2026-11-10
- **Décideur :** mainteneur du projet (à trancher)

## Contexte

Arch Linux ARM fournit **systemd 261**. systemd exige :

- un noyau **≥ 4.15** ;
- cgroup v2 ;
- l'API de montage récente.

Le noyau Switchroot (L4T) est un **4.9.140**. Il ne peut donc pas exécuter
systemd 261 : le démarrage s'arrête après `switch_root`, souvent sans message
clair.

Ce n'est pas un problème de configuration : c'est une incompatibilité de
versions. Aucun fichier de ce dépôt ne peut la corriger.

### Faits vérifiés

| Fait | Source |
|---|---|
| Noyau Switchroot = 4.9.140 | `configs/versions.lock`, documentation Switchroot |
| Arch Linux ARM = systemd 261 | retour d'expérience documenté par le projet `alarm-tegra-x1` |
| systemd ≥ 250 exige noyau ≥ 4.15 et cgroup v2 | documentation systemd |
| Un noyau mainline 7.x démarre sur HAC-001 avec un PID 1 script | projet `alarm-tegra-x1` |
| L'écran nécessite un pilote DSI absent du mainline nu | patches Switchroot / `alarm-tegra-x1` |

## Décision

**Aucune pour l'instant.** L'ADR est volontairement laissée ouverte : choisir
maintenant reviendrait à inventer un résultat non testé. Le projet documente
l'incompatibilité et empêche de la masquer.

Trois options sont à évaluer, dans cet ordre de préférence.

### Option A — Noyau mainline + patches Tegra (recommandée à évaluer)

- Utiliser un noyau ≥ 6.x avec les patches Tegra X1 (écran, tactile, USB) du
  projet Switchroot mainline ou d'`alarm-tegra-x1`.
- systemd fonctionne, l'écosystème Arch/Omarchy est intact.
- **Risque :** le pilote d'affichage et le GPU sont les points faibles ;
  l'accélération NVIDIA n'existe pas sur mainline (nouveau/NVK seulement).

### Option B — Init alternative (PID 1 script)

- Remplacer systemd par un script PID 1 minimal, comme le fait
  `alarm-tegra-x1`.
- Démarrage possible sur le noyau 4.9, mais on perd :
  NetworkManager géré par systemd, `uwsm`, les unités, `journalctl`, la session
  Omarchy standard.
- **Verdict probable :** incompatible avec l'objectif « expérience Omarchy ».

### Option C — Attendre un noyau L4T ≥ 4.15

- Aucun noyau L4T ≥ 4.15 avec support écran/GPU n'est publiquement disponible
  pour la Switch aujourd'hui.
- L4S maintient un noyau 4.9.140 : pas de progrès de ce côté.

## Alternatives écartées d'emblée

| Alternative | Pourquoi |
|---|---|
| Patcher systemd pour accepter 4.9 | Impossible : cgroup v2 et l'API de montage sont dans le noyau |
| Utiliser SysVinit/OpenRC sur Arch | Arch a supprimé ce support ; travail de fork complet |
| Garder Ubuntu pour systemd | Contraire à l'objectif du projet (Arch + Omarchy) |
| `systemd.unified_cgroup_hierarchy=0` | Ne résout pas l'absence de fonctionnalités noyau |

## Conséquences

Tant que l'ADR est ouverte :

- l'image peut être construite, mais **ne donnera pas de système utilisateur** ;
- `docs/05-status-matrix.md` marque systemd, Hyprland et le bureau comme
  **bloqués** ;
- la CI ne prétend pas produire une image fonctionnelle ;
- aucune release n'est décrite comme installable.

## Ce qu'il faut pour clore cette ADR

1. un test réel du noyau mainline patché sur la console (écran, entrées) ;
2. une mesure : le bureau tient-il 30 minutes sans crash ?
3. une décision écrite, avec les compromis acceptés.

## Références

- `docs/06-known-limitations.md`
- `alarm-tegra-x1` : <https://notdouble.com/p/alarm-tegra-x1>
- Switchroot mainline : <https://gitlab.com/switchroot/kernel/mainline-kernel>
- systemd, prérequis : <https://systemd.io/>
