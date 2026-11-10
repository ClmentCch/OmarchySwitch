# `switchroot/dtb/` — device trees Tegra 210 (Switch)

**Contenu attendu :** `nx-plat.dtimg`, l'image de device trees plateforme
utilisée par U-Boot (écran, régulateurs, USB, PCIe, tactile, Joy-Con, thermique).

## Pourquoi un `.dtimg` et pas un `.dtb`

U-Boot du bootstack Switchroot charge une image de device trees (format Android
`dtimg`) contenant plusieurs variantes, et sélectionne celle qui correspond à
la révision matérielle (Erista / Mariko, écran JDI / autres dalles). Fournir un
`.dtb` unique ne suffit pas.

## Origine

- Overlays et DTS : <https://gitlab.com/switchroot/kernel/l4t-device-tree-overlays>
- Device trees plateforme : `l4t-platform-t210-switch` dans
  <https://gitlab.com/switchroot/kernel>
- Version binaire : dans les fichiers de démarrage des releases Switchroot.

## Ce qui dépend du DTB

Sans `nx-plat.dtimg` correct, le noyau démarre mais :

- l'écran reste noir (aucun descripteur de la dalle DSI) ;
- le tactile `stmfts` n'est pas instancié ;
- les Joy-Con ne sont pas décrits (rails, I²C, charge) ;
- le Wi-Fi PCIe n'est pas alimenté (`ldo1` du MAX77620) ;
- la régulation thermique et les fréquences ne sont pas bornées.

C'est le composant le plus critique après le noyau, et le plus difficile à
diagnostiquer : une erreur produit un démarrage silencieux.

## Mise en place

```bash
./switchroot/scripts/import-components.sh --from /srv/switchroot-extracted
```

## Vérification

```bash
python3 - <<'PY'
from pathlib import Path
p = Path("switchroot/dtb/nx-plat.dtimg")
data = p.read_bytes()
print("magic:", data[:4], "size:", len(data))
PY
```

Le magic attendu est `D00DFEED` (format `dtimg`). Absent ou différent : le
fichier n'est pas un `dtimg`.
