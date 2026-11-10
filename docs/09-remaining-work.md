# 09 — Travail restant (ce que vous devez faire)

Tout ce qui suit ne peut pas être produit automatiquement : soit le fichier est
un binaire non redistribuable, soit il dépend de votre console, soit il exige une
décision de conception.

## 1. Composants Switchroot — bloquant

| Fichier attendu | Emplacement exact | Où le récupérer | Comment l'intégrer | Pourquoi vous seul pouvez le faire |
|---|---|---|---|---|
| `uImage` | `switchroot/kernel/uImage` | Release Switchroot (Ubuntu Bionic/Jammy) ou compilation de `l4t-kernel-4.9` | `./switchroot/scripts/import-components.sh --from <dir>` | GPL-2.0 : binaire non versionné ici, et doit correspondre à vos modules |
| `nx-plat.dtimg` | `switchroot/dtb/nx-plat.dtimg` | Release Switchroot / `l4t-device-tree-overlays` | idem | Décrit votre révision matérielle |
| `initramfs` | `switchroot/boot/initramfs` | Release Switchroot | idem | GPL-2.0, spécifique au bootstack |
| `boot.scr` | `switchroot/boot/boot.scr` | Release Switchroot / `switch-uboot-scripts` | idem | Doit correspondre au noyau et au DTB |
| `bl31.bin` | `switchroot/boot/bl31.bin` | Release Switchroot / `switch-atf` | idem | BSD-3-Clause, binaire non fourni |
| `bl33.bin` | `switchroot/boot/bl33.bin` | Release Switchroot / `switch-uboot` | idem | GPL-2.0-or-later |
| Modules `4.9.140*` | `switchroot/modules/4.9.140-l4t/...` | Image rootfs Switchroot (`/lib/modules`) | Monter l'image en lecture seule et copier | Doivent correspondre **exactement** au noyau |
| Firmware Wi-Fi/BT/GPU | `switchroot/firmware/...` | Image rootfs Switchroot (`/lib/firmware`) | idem | Blobs NVIDIA non redistribuables |

Après import :

```bash
./switchroot/scripts/import-components.sh --list-missing
sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs
```

## 2. hekate — à télécharger

| Fichier | Emplacement | Où | Pourquoi |
|---|---|---|---|
| `hekate_ctcaer_6.5.4.bin` | injecteur RCM | <https://github.com/CTCaer/hekate/releases> | Payload de démarrage |
| `bootloader/sys/*` | `sd:/bootloader/sys/` | même archive | Sans `nyx.bin`, `res.pak`, `libsys_lp0.bso`, `libsys_minerva.bso`, `sys/l4t/*`, L4T ne démarre pas |

```bash
./bootloader/scripts/install-bootfiles.sh --target /run/media/$USER/OMARCHYSW \
    --hekate-zip ~/Downloads/hekate_ctcaer_6.5.4.zip
```

## 3. Décision d'architecture — bloquant

| Sujet | Fichier | Ce que vous devez décider | Options |
|---|---|---|---|
| systemd vs noyau 4.9 | `docs/adr/0004-systemd-kernel-compatibility.md` | Quelle stratégie adopter | Noyau mainline patché (écran à valider), init script PID 1, ou attendre un noyau L4S ≥ 4.15 |

Sans cette décision, l'image peut démarrer jusqu'à l'initramfs mais **aucun
système utilisateur Arch/Omarchy ne se lancera**.

## 4. Tests matériels — bloquant

| Test | Où | Ce qu'il faut fournir |
|---|---|---|
| Démarrage hekate → noyau | console | Une Switch V1, l'entrée debug, le log écran/USB |
| Montage du rootfs | console | Le message exact de l'initramfs |
| systemd | console | La sortie du noyau après `switch_root` |
| Wi-Fi, Bluetooth, audio, Joy-Con, tactile | console | Résultats par sous-système |
| Veille/reprise, charge | console | Mesures et journaux |

Protocole : [`10-testing.md`](10-testing.md). Remplir ensuite
`docs/05-status-matrix.md` et `hardware/aarch64-tegra-x1/features.toml`.

## 5. Empreintes à épingler

| Fichier | Champ | Pourquoi |
|---|---|---|
| `configs/local.conf` | `ALARM_TARBALL_SHA256` | Le tarball Arch ARM est régénéré |
| `switchroot/manifest.local.toml` | généré | Produit par `import-components.sh` |
| `archlinux/packages/linux-switchroot/PKGBUILD` | `sha256sums` | Actuellement `SKIP` (marqué TODO) |

## 6. Ce qui n'est PAS nécessaire de fournir

| Élément | Pourquoi |
|---|---|
| Un noyau prêt pour systemd | N'existe pas publiquement pour Tegra X1 + écran + GPU |
| Des pilotes Tegra | Fournis par le noyau Switchroot |
| Une licence NVIDIA | Non redistribuable ; usage personnel de l'image |

## 7. Ordre recommandé

```text
1. Importer les composants Switchroot + empreintes
2. Construire le rootfs, intégrer Switchroot, construire l'image
3. Tester le démarrage jusqu'à l'initramfs (entrée debug)
4. Décider la stratégie systemd (ADR 0004)
5. Seulement ensuite : intégrer Omarchy et le bureau
6. Documenter les résultats réels dans la matrice d'état
```
