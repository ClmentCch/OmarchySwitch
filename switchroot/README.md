# `switchroot/` — couche de compatibilité matérielle Nintendo Switch

Ubuntu Bionic Switchroot n'est **pas** le système utilisateur d'OmarchySwitch.
Seuls ses composants noyau/matériel sont conservés, et ils sont fournis par
vous : aucun binaire Switchroot n'est versionné dans ce dépôt.

## Pourquoi ces composants sont indispensables

| Composant | Sans lui |
|---|---|
| `uImage` (noyau L4T 4.9.140) | Rien ne démarre : hekate/U-Boot n'ont pas de noyau |
| `nx-plat.dtimg` (DTB) | Pas d'écran, pas de tactile, pas de Joy-Con : le matériel n'est pas décrit |
| `bl31.bin` (ATF) | Pas de secure monitor : U-Boot ne démarre pas |
| `bl33.bin` (U-Boot) | hekate n'a pas d'étage de chargement |
| `boot.scr` | U-Boot ne sait pas quoi charger |
| `initramfs` | Le rootfs Arch n'est jamais monté |
| modules noyau | Wi-Fi, Bluetooth, audio, Joy-Con, charge : morts |
| firmware | Les pilotes chargent mais le matériel reste muet |

## Un fait à accepter avant de continuer

Le noyau Switchroot est un **4.9.140** issu du BSP NVIDIA L4T. Arch Linux ARM
livre **systemd 261**, qui exige un noyau ≥ 4.15 et cgroup v2. **Arch + Omarchy
ne peut donc pas démarrer tel quel sur ce noyau.** Les options réelles sont
documentées dans
[`../docs/adr/0004-systemd-kernel-compatibility.md`](../docs/adr/0004-systemd-kernel-compatibility.md).
Ce dépôt ne masque pas le problème : il l'isole dans une ADR et dans
`docs/06-known-limitations.md`.

## Où récupérer les composants

Sources officielles, dans cet ordre de préférence :

1. **Images Switchroot officielles** (Ubuntu Bionic / Jammy, Fedora L4S) :
   <https://wiki.switchroot.org/wiki/linux/l4t-ubuntu-bionic-installation-guide>
   Les archives de boot contiennent `uImage`, `initramfs`, `nx-plat.dtimg`,
   `boot.scr`, `bl31.bin`, `bl33.bin`. Les modules et le firmware sont dans
   l'image ext4 du rootfs (label `SWR-*`).
2. **Sources kernel Switchroot** (si vous voulez compiler vous-même) :
   - noyau : <https://gitlab.com/switchroot/kernel/l4t-kernel-4.9>
     (tag de référence : `linux-5.1.0_r2`, branche `lineage-19.1`)
   - U-Boot : <https://gitlab.com/switchroot/bootstack/switch-uboot>
   - ATF : <https://gitlab.com/switchroot/bootstack/switch-atf>
   - initramfs : <https://gitlab.com/switchroot/kernel/l4t-initramfs>
   - overlays DT : <https://gitlab.com/switchroot/kernel/l4t-device-tree-overlays>
3. **L4S (Linux 4 Switch)** pour le noyau Fedora maintenu :
   <https://azka.li/linux-4-switch> — à considérer pour la suite, mais son
   noyau 4.9.140 reste trop ancien pour systemd.

## Licences et redistribution

| Composant | Licence | Redistribution dans ce dépôt |
|---|---|---|
| Noyau L4T | GPL-2.0 | Non (binaire), source uniquement si vous redistribuez |
| ATF | BSD-3-Clause | Non |
| U-Boot | GPL-2.0-or-later | Non |
| Initramfs | GPL-2.0 | Non |
| DTBs | GPL-2.0 | Non |
| Firmware / blobs NVIDIA | Propriétaire NVIDIA | **Non, jamais** |

Conséquence pratique : vous pouvez construire et utiliser une image pour vous ;
la publier publiquement exige de respecter la GPL (sources) et interdit d'y
inclure les blobs NVIDIA sans autorisation. Voir `../THIRD-PARTY.md`.

## Où placer les fichiers

```text
switchroot/
├── kernel/uImage                  # noyau L4T
├── dtb/nx-plat.dtimg              # device trees plateforme
├── boot/initramfs                 # initramfs Switchroot
├── boot/boot.scr                  # script U-Boot
├── boot/bl31.bin                  # ATF
├── boot/bl33.bin                  # U-Boot
├── modules/4.9.140-l4t/...        # arborescence /usr/lib/modules
└── firmware/...                   # arborescence /lib/firmware
```

Les binaires sont ignorés par Git (`.gitignore` du dossier) : ils ne peuvent
pas être ajoutés par erreur.

## Comment les intégrer

### 1. Importer et mesurer les empreintes

```bash
# Depuis un répertoire où vous avez extrait les fichiers du bootstack
# et copié les modules/firmware depuis l'image ext4 du rootfs Switchroot.
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted

# Le script copie dans switchroot/{kernel,dtb,boot,modules,firmware}
# et écrit les SHA-256 dans switchroot/manifest.local.toml
```

### 2. Vérifier la cohérence

```bash
./switchroot/scripts/import-components.sh --list-missing
```

### 3. Intégrer au rootfs et à l'arbre de boot

```bash
sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs
```

Le script refuse tout fichier sans empreinte, vérifie la correspondance
noyau/modules, et écrit `/etc/omarchyswitch/switchroot-provenance.txt`.

## Extraire les modules et le firmware d'une image Switchroot

Les images de rootfs Switchroot sont des images ext4 (souvent découpées en
`l4t.00`, `l4t.01`, ... à concaténer). Sur un hôte Linux avec root :

```bash
# Concaténer les parties si nécessaire
cat l4t.0* > switchroot-rootfs.img

# Monter en lecture seule
sudo mkdir -p /mnt/swr
sudo mount -o loop,ro switchroot-rootfs.img /mnt/swr

# Copier modules et firmware
sudo cp -a /mnt/swr/lib/modules/. switchroot/modules/
sudo cp -a /mnt/swr/lib/firmware/. switchroot/firmware/

sudo umount /mnt/swr
```

Puis lancer `import-components.sh --from switchroot` pour mesurer les
arborescences copiées (les fichiers sont déjà au bon endroit).

## Ce que ce dossier ne fait pas

- Il ne récupère rien automatiquement : les URL de release changent et les
  blobs NVIDIA ne sont pas redistribuables.
- Il ne compile pas le noyau : `archlinux/packages/linux-switchroot/PKGBUILD`
  montre comment le faire, mais le paquet n'a pas été construit pour cette
  version (marqué « à tester »).
- Il ne prétend pas que l'ensemble fonctionne : voir
  [`../docs/05-status-matrix.md`](../docs/05-status-matrix.md).
