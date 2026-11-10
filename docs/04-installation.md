# 04 — Installation sur la console

> **Aucune image produite par ce dépôt n'a été testée sur une console.**
> Ce document décrit la procédure prévue et les points de contrôle ; il ne
> garantit pas un démarrage.

## Avant de commencer

| Prérequis | Détail |
|---|---|
| Switch V1 (Erista) | Mariko non supporté |
| microSD | 16 Gio minimum, classe A2/U3 recommandée |
| Injecteur RCM | PC + câble USB, dongle, ou téléphone |
| hekate | release `v6.5.4` ou plus récente |
| Sauvegarde | dump eMMC/Horizon OS réalisé **avant** toute manipulation |

L'eMMC n'est jamais touchée par ces scripts. Une carte SD ne peut pas rendre
Horizon OS inutilisable ; une manipulation de l'eMMC, si.

## 1. Écrire l'image

```bash
sudo ./installer/scripts/install.sh \
     --device /dev/sdX \
     --image build/output/omarchyswitch-0.1.0.img
```

Le script vérifie l'empreinte, refuse un périphérique monté, affiche le modèle et
la taille, demande confirmation, écrit puis relit les premiers mégaoctets.

Alternative manuelle :

```bash
sudo dd if=build/output/omarchyswitch-0.1.0.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

## 2. Installer hekate

1. extraire la release hekate ;
2. copier son dossier `bootloader/` à la racine de la partition FAT ;
3. installer la configuration OmarchySwitch :

```bash
./bootloader/scripts/install-bootfiles.sh \
    --target /run/media/$USER/OMARCHYSW \
    --hekate-zip ~/Downloads/hekate_ctcaer_6.5.4.zip
```

Le script signale les fichiers `bootloader/sys/` manquants : sans eux, L4T ne
démarre pas.

## 3. Démarrer

1. insérer la carte ;
2. entrer en RCM (VOL+ maintenu, appuyer sur Power) ;
3. injecter hekate ;
4. dans le menu, ouvrir **More configs...** ;
5. choisir **OmarchySwitch (Erista)**.

Pour le premier essai, préférer **OmarchySwitch (Erista) debug** : il affiche le
log noyau sur la dalle et sur USB.

## 4. Ce à quoi s'attendre

| Étape | Attendu | Probable |
|---|---|---|
| hekate charge l'entrée | écran de boot hekate | oui |
| ATF/U-Boot | quelques secondes | oui |
| Noyau | log noyau (entrée debug) | oui |
| Initramfs | montage du rootfs | oui si label correct |
| systemd | démarrage complet | **non** (voir ADR 0004) |

Le point d'arrêt attendu est donc **après l'initramfs**, au démarrage de
systemd. Ce n'est pas un bug de configuration : c'est une incompatibilité de
version de noyau.

## 5. Diagnostic

```bash
# Depuis un hôte, carte montée
./recovery/diagnostics/collect.sh --sd /run/media/$USER/OSWITCH
```

Voir aussi [`02-boot-chain.md`](02-boot-chain.md) (table des symptômes) et
[`06-known-limitations.md`](06-known-limitations.md).

## 6. Retour en arrière

| Objectif | Action |
|---|---|
| Revenir à Horizon OS | éteindre, retirer la carte (ou choisir l'entrée Horizon dans hekate) |
| Restaurer la configuration de boot | `recovery/restore/restore-bootfiles.sh` |
| Effacer la carte | `wipefs -a /dev/sdX` puis re-partitionner |

## Avertissements

- Ne jamais flasher une image sur l'eMMC via ces scripts.
- Ne pas utiliser `--force` sans avoir vérifié le périphérique affiché.
- Ne pas retirer la carte pendant une écriture.
- Un écran noir n'est pas une panne : c'est le symptôme par défaut de presque
  toutes les erreurs de chaîne de boot.
