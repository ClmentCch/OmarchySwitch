# Diagnostics

`collect.sh` produit une archive `tar.gz` contenant l'état d'une carte
OmarchySwitch, destinée à être jointe à un rapport de bug.

## Ce qui est collecté

- arborescence de la partition FAT (`bootloader/`, `switchroot/`) ;
- contenu des fichiers `.ini` (aucun secret n'y est stocké) ;
- empreintes SHA-256 des fichiers de boot ;
- présence de `bootloader/sys/` et des fichiers L4T ;
- `etc/fstab`, `etc/switchroot_version.conf`, `etc/omarchyswitch/*` du rootfs ;
- liste des modules noyau présents et version ;
- journaux : `omarchyswitch-firstboot.log`, `journal/` si présent ;
- informations de partitionnement (`lsblk`, `parted print`).

## Ce qui n'est **jamais** collecté

- `/home/*` (documents, identifiants Git, clés SSH) ;
- `/etc/shadow`, `/etc/passwd` (au-delà de la liste des noms) ;
- configuration Wi-Fi (SSID et mot de passe) ;
- dumps de pairing Joy-Con ;
- clés `machine-id` (remplacé par une mention « présent/absent »).

Le script refuse de suivre des liens symboliques hors de la carte, pour éviter
de copier des fichiers de l'hôte par erreur.

## Usage

```bash
# Carte montée (rootfs sur /run/media/$USER/OSWITCH, boot sur .../OMARCHYSW)
./recovery/diagnostics/collect.sh --sd /run/media/$USER/OSWITCH

# Depuis une image disque (root requis pour le montage en lecture seule)
sudo ./recovery/diagnostics/collect.sh --image build/output/omarchyswitch.img
```

L'archive est écrite dans `build/output/diagnostics/` et son contenu est listé à
la fin de l'exécution : vérifiez-le avant de le partager.
