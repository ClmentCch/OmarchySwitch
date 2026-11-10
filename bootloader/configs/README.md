# `bootloader/configs/` — entrées hekate prêtes à copier

| Fichier | Destination sur la partition FAT | Usage |
|---|---|---|
| `omarchyswitch-erista.ini` | `bootloader/ini/omarchyswitch-erista.ini` | Entrée normale : pas de log noyau à l'écran, démarrage propre |
| `omarchyswitch-erista-debug.ini` | `bootloader/ini/omarchyswitch-erista-debug.ini` | Bring-up : log noyau sur la dalle et sur USB |

Les deux fichiers sont des **entrées additionnelles** : ils n'écrasent pas la
configuration Horizon OS existante et n'altèrent pas le démarrage par défaut.

## Différences

| Clé | Normal | Debug | Pourquoi |
|---|---|---|---|
| `fbconsole` | `9` (aucun affichage noyau) | `0` (log sur la dalle) | Le log noyau sur la dalle empêche la reprise propre par le pilote d'affichage |
| `uart_port` | absent (`0`) | `4` (USB) | Sur console retail, il n'y a pas d'UART de maintenance |
| `earlycon` | absent | `1` | Affiche les erreurs avant l'initialisation du pilote série |
| `bootargs_extra` | absent | `loglevel=7` | Verbosité maximale pendant le bring-up |

## Vérification des fichiers avant de flasher

```bash
./scripts/validate-architecture.sh          # syntaxe des .ini
```

## Clés interdites ou à ne pas copier

- `id=` : **7 caractères maximum** (limite hekate). Il doit correspondre au
  label ext4 de la partition Linux. La valeur par défaut du projet est
  `OSWITCH`.
- `boot_prefixes=` : doit correspondre au répertoire réellement présent sur la
  partition FAT (`/switchroot/omarchyswitch/`).
- Ne pas ajouter `emmc=1` sans raison : cela autorise le démarrage depuis le
  stockage interne, ce qui n'est pas supporté par cette base.
- Ne pas reprendre les clés `dvfsb`, `gpu_dvfsc`, `limit_gpu_clk`, `ram_oc*`
  des fichiers Mariko (T210B01) : elles ne s'appliquent pas à Erista et
  certaines sont explicitement réservées à T210B01.
