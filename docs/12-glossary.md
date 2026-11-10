# 12 — Glossaire

| Terme | Définition |
|---|---|
| **Erista** | Révision du SoC Tegra X1 des Switch 2017 (HAC-001), vulnérable à RCM |
| **Mariko** | Révision T210B01 (2019, Lite, OLED) : hors périmètre |
| **Tegra X1 / T210** | SoC NVIDIA : 4× A57 + 4× A53, GPU GM20B |
| **GM20B** | GPU Maxwell intégré au Tegra X1 |
| **RCM** | *Recovery Mode* du bootrom Tegra, accessible via CVE-2018-6242 sur Erista |
| **hekate** | Bootloader custom (payload RCM), avec L4T Loader et interface Nyx |
| **L4T** | *Linux for Tegra*, BSP NVIDIA (noyau 4.9.140 pour cette plateforme) |
| **BSP** | *Board Support Package* : noyau, pilotes, blobs fournis par le fabricant |
| **ATF / bl31** | ARM Trusted Firmware, secure monitor ; lancé par hekate, lance U-Boot |
| **bl33 / U-Boot** | Étage de chargement qui exécute `boot.scr` et démarre le noyau |
| **boot.scr** | Script U-Boot compilé (`mkimage -T script`) |
| **DTB / DTIMG** | *Device Tree Blob* / image de plusieurs DTB (format Android) |
| **nx-plat.dtimg** | Image de device trees plateforme de la Switch |
| **initramfs** | Système de fichiers temporaire qui monte le rootfs puis `switch_root` |
| **switch_root** | Passage de l'initramfs au système réel |
| **uImage** | Format de noyau U-Boot (en-tête 64 octets), attendu par le L4T Loader |
| **nvgpu** | Pilote GPU NVIDIA propriétaire du BSP |
| **nouveau / NVK** | Pilotes GPU libres (expérimentaux sur T210) |
| **brcmfmac** | Pilote Wi-Fi Broadcom (BCM4356 sur la Switch) |
| **stmfts** | Pilote du contrôleur tactile STMicroelectronics |
| **LP0** | État de veille profond (suspend to RAM) du Tegra |
| **nvpmodel** | Outil NVIDIA de profils de performance (blob BSP) |
| **Omarchy** | Distribution Arch + Hyprland de DHH, sous MIT |
| **Hyprland** | Compositeur Wayland dynamique |
| **Waybar** | Barre d'état Wayland |
| **Walker** | Lanceur d'applications Wayland |
| **uwsm** | Gestionnaire de session Wayland pour systemd |
| **ALARM** | Arch Linux ARM |
| **PKGBUILD** | Recette de construction d'un paquet Arch |
| **pacman** | Gestionnaire de paquets Arch |
| **ADR** | *Architecture Decision Record* : décision documentée avec contexte |
| **GPT** | Table de partitions GUID (utilisée par l'image) |
