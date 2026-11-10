# 10 — Protocole de test

Objectif : obtenir des résultats reproductibles et comparables, sans casser la
console ni Horizon OS.

## Règles

1. **Une variable à la fois.** Un test = un changement.
2. **Toujours partir de l'entrée debug** pour un nouveau build (`fbconsole=0`).
3. **Noter le résultat, même négatif.** « Écran noir, LED allumée, pas de son »
   est une donnée utile.
4. **Ne jamais tester sur l'eMMC.**
5. **Conserver une carte de référence** qui a déjà démarré (quand il y en aura
   une) pour distinguer un problème de carte d'un problème d'image.

## Matériel nécessaire

| Élément | Pourquoi |
|---|---|
| Switch V1 (Erista) | Cible |
| Carte microSD 16 Gio+ | Support |
| Injecteur RCM | Démarrage |
| Câble USB + PC | Log USB (`uart_port=4`) |
| Chargeur d'origine | Tester la charge |
| Joy-Con (paire) | Tester HID et Bluetooth |
| Dock + écran HDMI | Tester la sortie externe |

## Séquence

### T1 — hekate charge l'entrée

1. Carte écrite, hekate installé, entrée `OmarchySwitch (Erista) debug` présente.
2. Entrer en RCM, injecter hekate, choisir l'entrée.
3. **Attendu** : le menu hekate disparaît, la console tente de démarrer.
4. **Échec** : retour immédiat au menu → `bootloader/sys` ou `boot_prefixes`.

Noter : capture d'écran, heure, version hekate.

### T2 — noyau

1. Brancher l'USB sur un PC, ouvrir le port série (`minicom -D /dev/ttyACM0`).
2. **Attendu** : messages du noyau, puis de l'initramfs.
3. **Échec** : rien → noyau absent/incompatible ; log qui s'arrête → identifier
   le dernier pilote chargé.

Noter : les 100 dernières lignes du log.

### T3 — rootfs

1. **Attendu** : l'initramfs trouve la partition par label et monte le rootfs.
2. **Échec** : `failed to mount rootfs` → label, options ext4 ;
   `not a switchroot installation` → marqueur manquant.

### T4 — système

1. **Attendu (si ADR 0004 résolu)** : systemd démarre, `graphical.target`.
2. **Attendu (état actuel)** : arrêt après `switch_root` → confirme le blocage.

Noter : les messages exacts de systemd.

### T5 — matériel

À exécuter seulement si le système démarre :

| Test | Commande | Résultat attendu |
|---|---|---|
| Écran | affichage de la session | image nette, orientation correcte |
| Tactile | `libinput debug-events` | coordonnées cohérentes après rotation |
| Wi-Fi | `nmcli device status` | `wlan0` connecté |
| Bluetooth | `bluetoothctl show` | `hci0` présent |
| Audio | `wpctl status` + `speaker-test` | son sur les haut-parleurs |
| Joy-Con | `evtest` | événements des boutons |
| Batterie | `upower -i ...` | pourcentage cohérent |
| Veille | `systemctl suspend` | reprise correcte |
| Dock | brancher le dock | sortie HDMI détectée |

## Rapport

Pour chaque test, produire :

```text
Test:        T2
Date:        2026-..-..
Build:       commit <sha>, image sha256 <...>
Entrée:      OmarchySwitch (Erista) debug
Résultat:    échec
Observation: le log s'arrête après "tegra-dc: ..."
Fichiers:    log noyau, capture d'écran
```

Joindre une archive de diagnostic :

```bash
./recovery/diagnostics/collect.sh --sd /run/media/$USER/OSWITCH
```

## Mise à jour de la documentation

Après un test réussi :

1. passer la ligne concernée à `fonctionnel` dans
   `hardware/aarch64-tegra-x1/features.toml` ;
2. mettre à jour `docs/05-status-matrix.md` ;
3. ajouter une entrée dans `CHANGELOG.md` si le comportement change.

Un test réussi qui n'est pas écrit ne compte pas : le prochain contributeur
repartira de zéro.
