# 0003 — Aucun binaire matériel versionné dans le dépôt

- **Statut :** acceptée
- **Date :** 2026-11-10

## Contexte

Une distribution « prête à flasher » serait plus simple pour l'utilisateur. Elle
exigerait de versionner ou de publier :

- le noyau L4T (GPL-2.0) ;
- les modules et le firmware (dont blobs NVIDIA propriétaires) ;
- les DTBs (GPL-2.0) ;
- ATF (BSD-3-Clause) et U-Boot (GPL-2.0+) ;
- éventuellement le binaire hekate (GPL-2.0).

## Décision

**Aucun binaire matériel n'est versionné ni publié par ce dépôt.** Le dépôt
contient :

- des emplacements documentés (`switchroot/kernel/`, `dtb/`, `modules/`,
  `firmware/`, `boot/`) ;
- un manifeste déclaratif (`switchroot/manifest.toml`) ;
- un script d'import qui mesure les empreintes
  (`switchroot/scripts/import-components.sh`) ;
- un script d'intégration qui refuse tout fichier non vérifié.

Les releases du projet contiennent uniquement du texte : scripts, configurations,
documentation, manifestes.

## Alternatives considérées

| Alternative | Rejetée parce que |
|---|---|
| Tout inclure dans la release | Blobs NVIDIA non redistribuables ; GPL exigerait les sources ; dépôt de plusieurs Go |
| Inclure seulement le noyau | Sans modules/firmware, le système est inutilisable et l'utilisateur croit à un bug |
| Lien direct vers une release Switchroot | Fragile (URL/version), et donne l'illusion d'une intégration testée |
| Sous-module Git vers les sources | Ne donne pas les binaires et alourdit le clone |

## Conséquences

**Positives**

- conformité licences (aucune redistribution de blobs propriétaires) ;
- dépôt léger, clonable en quelques secondes ;
- traçabilité : chaque fichier matériel est identifié par une empreinte locale.

**Négatives**

- l'utilisateur doit faire une étape manuelle ;
- pas de « télécharger et flasher » ;
- une release ne suffit pas à reconstruire une image complète.

**Mesures d'atténuation**

- `docs/09-remaining-work.md` liste chaque fichier, sa source et la commande ;
- l'intégration échoue avec un message qui indique exactement quoi faire ;
- `import-components.sh --list-missing` donne l'état en une commande ;
- la validation refuse tout fichier de plus de 1 Mio dans le dépôt.

## Références

- `THIRD-PARTY.md`
- `switchroot/README.md`
- `LICENSE` (périmètre de la licence MIT du projet)
