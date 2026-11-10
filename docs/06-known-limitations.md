# 06 — Limites connues

Chaque limite est écrite avec sa cause et son impact, pour éviter les fausses
pistes de diagnostic.

## 1. systemd ne démarre pas sur le noyau 4.9.140 — **bloquant**

| | |
|---|---|
| Cause | Arch Linux ARM fournit systemd 261 ; il exige un noyau ≥ 4.15 et cgroup v2. Le noyau Switchroot est 4.9.140. |
| Impact | Pas de `NetworkManager`, pas de session `uwsm`, pas de `graphical.target`, pas d'unité de premier démarrage. |
| Ce qui ne marche pas | Tout ce qui dépend de systemd, c'est-à-dire la quasi-totalité du système utilisateur. |
| Options | Voir [ADR 0004](adr/0004-systemd-kernel-compatibility.md) |
| Ce qui ne marchera pas | Un simple `--sysvinit` ou un `rc.local` : Arch n'est plus conçu pour ça. |

C'est la limite la plus importante du projet. Elle est structurelle, pas
accidentelle.

## 2. Aucun composant matériel n'est fourni

| | |
|---|---|
| Cause | Les binaires Switchroot et les blobs NVIDIA ne sont pas redistribuables ici. |
| Impact | Sans eux, l'image ne contient aucun noyau : elle ne démarre pas. |
| Solution | `switchroot/README.md` + `switchroot/scripts/import-components.sh` |

## 3. Le noyau mainline ne gère pas l'écran

| | |
|---|---|
| Cause | Le pilote de la dalle JDI (DSI) et la configuration des rails viennent du BSP L4T. |
| Impact | Un noyau mainline démarre mais n'affiche rien, et n'a pas de console série sur console retail. |
| État | Bring-up existant chez des tiers (projet `alarm-tegra-x1`), non intégré ici. |

## 4. Le GPU dépend des blobs NVIDIA

| | |
|---|---|
| Cause | `nvgpu` est un blob du BSP ; `nouveau` sur T210 est expérimental. |
| Impact | Sans les blobs, Hyprland échoue à créer un contexte EGL. |
| Conséquence | Le chemin « tout libre » n'est pas encore viable pour un bureau complet. |

## 5. Wi-Fi et Bluetooth silencieux en cas de firmware manquant

| | |
|---|---|
| Cause | Les pilotes échouent sans message visible dans un log noyau absent. |
| Impact | `wlan0` n'apparaît jamais ; l'utilisateur croit à un problème de configuration réseau. |
| Prévention | `integrate-switchroot.sh` vérifie la présence de `brcmfmac4356-pcie.bin/.txt` ; le premier démarrage écrit un avertissement. |

## 6. Pas de clavier physique au démarrage

| | |
|---|---|
| Cause | Console portable. |
| Impact | Pas de saisie de mot de passe au boot ; l'autologin est nécessaire, la sécurité repose sur l'accès physique. |
| Conséquence | Aucun mot de passe par défaut n'est livré : le compte est verrouillé jusqu'à ce que l'utilisateur en définisse un. |

## 7. La carte SD est le seul média supporté

| | |
|---|---|
| Cause | L'eMMC contient Horizon OS ; une erreur de partitionnement la détruit. |
| Impact | Performances limitées, usure de la carte. |
| Décision | `emmc=1` absent des configurations ; les scripts refusent d'écrire sur un périphérique monté. |

## 8. Mariko non supporté

| | |
|---|---|
| Cause | PMIC, DVFS et support noyau différents ; RCM n'existe pas. |
| Impact | Les configurations hekate Mariko (`dvfsb`, `gpu_dvfsc`, `ram_oc*`) sont volontairement absentes. |

## 9. Pas de dual-boot documenté

| | |
|---|---|
| Cause | Une carte peut contenir plusieurs entrées hekate, mais le projet ne fournit pas de schéma validé pour cohabiter avec une autre distribution Linux sur la même carte. |
| Impact | Utiliser une carte dédiée à OmarchySwitch. |

## 10. Aucun test matériel

| | |
|---|---|
| Cause | L'environnement de développement n'a pas de console. |
| Impact | Tous les états « préparé », « à tester » et « bloqué » de [`05-status-matrix.md`](05-status-matrix.md) sont réels. |
| Protocole | [`10-testing.md`](10-testing.md) |
