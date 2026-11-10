# Documentation OmarchySwitch

| Document | Contenu |
|---|---|
| [00-overview](00-overview.md) | Objectif, périmètre, ce que le projet est et n'est pas |
| [01-architecture](01-architecture.md) | Couches, responsabilités, décisions (avec liens ADR) |
| [02-boot-chain](02-boot-chain.md) | Chaîne de démarrage réelle, fichier par fichier |
| [03-build](03-build.md) | Construire le rootfs, l'arbre de boot et l'image |
| [04-installation](04-installation.md) | Écrire une carte, démarrer, premier boot |
| [05-status-matrix](05-status-matrix.md) | **État réel** de chaque fonctionnalité |
| [06-known-limitations](06-known-limitations.md) | Limites connues et leurs causes |
| [07-upstream-sources](07-upstream-sources.md) | Sources officielles, versions, licences |
| [08-packaging](08-packaging.md) | Paquets Arch, conventions, ce qui est packagé |
| [09-remaining-work](09-remaining-work.md) | **Ce que vous devez fournir**, fichier par fichier |
| [10-testing](10-testing.md) | Protocole de test sur console |
| [11-roadmap](11-roadmap.md) | Étapes suivantes, dans l'ordre |
| [12-glossary](12-glossary.md) | Termes Tegra, L4T, hekate, DTB, etc. |
| [adr/](adr/README.md) | Décisions d'architecture (ADR) |
| [research/](research/README.md) | Notes de recherche upstream (Omarchy, Switchroot) |

## Convention de statut

Les documents utilisent quatre états, sans nuance marketing :

| État | Signification |
|---|---|
| **terminé** | écrit, exécuté et vérifié dans cet environnement |
| **préparé** | fichiers et scripts écrits, jamais exécutés sur du matériel réel |
| **bloqué** | impossible sans un composant, une décision ou du matériel manquant |
| **à tester** | plausible, mais aucune vérification n'a été faite |

Si un document dit « fonctionne », c'est qu'un test réel l'a montré. Dans le
doute, la réponse est « préparé ».
