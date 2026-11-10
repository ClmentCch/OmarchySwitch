# 0002 — Conserver la chaîne hekate / L4T / ATF / U-Boot

- **Statut :** acceptée
- **Date :** 2026-11-10

## Contexte

La Switch ne dispose pas d'UEFI ni de chargeur standard. Les options réalistes :

1. hekate + L4T Loader + ATF + U-Boot (chaîne Switchroot) ;
2. hekate chargeant directement un noyau + DTB ;
3. un chargeur alternatif (coreboot, UEFI EDK2 expérimental, kexec).

hekate **ne démarre pas** un couple `Image` + `.dtb` : il passe par son L4T
Loader, qui prépare ATF/U-Boot et leur transmet les clés `.ini`.

## Décision

Conserver la chaîne Switchroot telle quelle :

```text
hekate → L4T Loader → ATF (bl31) → U-Boot (bl33) → boot.scr → uImage + dtimg + initramfs
```

Le projet ne modifie aucun de ces binaires en 0.1.0. Il fournit les fichiers
`.ini`, l'arborescence de boot et la vérification des composants.

## Alternatives considérées

| Alternative | Rejetée parce que |
|---|---|
| hekate → noyau direct | Non supporté par hekate pour Linux sur cette plateforme |
| UEFI EDK2 (`NintendoSwitchPkg`) | Expérimental, support écran/stockage partiel, pas de support communautaire stable |
| coreboot | Utilisé par certains projets, mais moins documenté et sans bénéfice pour ce cas |
| kexec depuis Horizon | Impossible sans faille logicielle et hors périmètre |

## Conséquences

**Positives**

- chemin le mieux documenté et le plus utilisé par la communauté ;
- fonctionnalités matérielles disponibles via le noyau L4T ;
- mises à jour indépendantes : on peut changer de noyau Switchroot sans changer
  hekate.

**Négatives**

- dépendance à des binaires non redistribuables ;
- compatibilité noyau limitée (4.9), donc ADR 0004 ;
- le couple noyau/modules/DTB doit rester cohérent : d'où le manifeste et la
  vérification d'empreintes.

**Obligations pratiques**

- `boot_prefixes` doit contenir `uImage`, `initramfs`, `nx-plat.dtimg`,
  `boot.scr`, `bl31.bin`, `bl33.bin` ;
- `bootloader/sys/l4t/` doit être complet ;
- `id=` (7 caractères max) doit correspondre au label ext4.

## Références

- hekate : <https://github.com/CTCaer/hekate>
- Bootstack Switchroot : <https://wiki.switchroot.org/wiki/linux/linux-bootstack-documentation>
- `README_CONFIG.txt` du bootstack (clés `.ini`)
