# 11 — Feuille de route

Ordre volontaire : d'abord ce qui débloque le démarrage, ensuite le confort.

## Phase 0 — Base technique (fait, version 0.1.0)

- [x] Arborescence, documentation, scripts
- [x] Configuration hekate modèle
- [x] Mécanisme d'intégration Switchroot vérifié par empreinte
- [x] Bootstrap Arch Linux ARM64
- [x] Adaptations Omarchy (surcharges)
- [x] CI de validation et packaging
- [ ] Tests matériels

## Phase 1 — Démarrage jusqu'à l'initramfs

- [ ] Importer les composants Switchroot et épingler les empreintes
- [ ] Construire une image et démarrer l'entrée debug
- [ ] Documenter le log noyau réel
- [ ] Corriger les écarts constatés (labels, chemins, options ext4)

**Critère de sortie :** l'initramfs monte le rootfs et tente `switch_root`.

## Phase 2 — Système utilisateur

- [ ] Choisir la stratégie de compatibilité noyau/systemd (ADR 0004)
- [ ] Si noyau mainline : évaluer l'état du pilote d'écran et des patches
      Switchroot
- [ ] Si init script : définir un PID 1 minimal, documenter ce qui est perdu
- [ ] Obtenir un shell root sur la console

**Critère de sortie :** un shell interactif sur la console, avec stockage monté
en lecture/écriture.

## Phase 3 — Réseau et périphériques

- [ ] Wi-Fi (firmware + NetworkManager ou alternative)
- [ ] Bluetooth (firmware + BlueZ)
- [ ] Audio (PipeWire)
- [ ] Tactile et rotation
- [ ] Joy-Con
- [ ] Batterie et charge

**Critère de sortie :** réseau opérationnel et entrées utilisables.

## Phase 4 — Bureau Omarchy

- [ ] Session Hyprland via uwsm
- [ ] Waybar, Walker, terminal
- [ ] Thèmes et polices
- [ ] Réglages GPU (effets, VFR)
- [ ] Veille/reprise

**Critère de sortie :** une session graphique utilisable au quotidien.

## Phase 5 — Distribution

- [ ] Paquets Arch officiels du projet (dépôt)
- [ ] Mises à jour sûres (noyau, modules, firmware)
- [ ] Installateur semi-automatisé
- [ ] Images publiées avec sources GPL correspondantes
- [ ] Documentation utilisateur finale

## Ce qui n'est pas planifié

| Élément | Raison |
|---|---|
| Mariko (2019/Lite/OLED) | Matériel et noyau différents |
| Installation sur eMMC | Risque pour Horizon OS |
| Chiffrement du rootfs | Complexité et risque de perte de données |
| Support du dock comme fonctionnalité principale | Dépend de la stabilité HDMI/CEC |
| Jeux/émulation intégrés | Choix utilisateur, hors distribution |
