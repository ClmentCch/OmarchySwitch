# Décisions d'architecture (ADR)

Format : contexte → décision → conséquences. Une ADR n'est pas modifiée après
acceptation ; une nouvelle décision la remplace explicitement.

| Numéro | Sujet | État |
|---|---|---|
| [0001](0001-arch-linux-arm-base.md) | Arch Linux ARM64 comme système principal | acceptée |
| [0002](0002-hekate-l4t-boot-chain.md) | Conserver la chaîne hekate / L4T / ATF / U-Boot | acceptée |
| [0003](0003-no-vendored-binaries.md) | Aucun binaire matériel dans le dépôt | acceptée |
| [0004](0004-systemd-kernel-compatibility.md) | Compatibilité systemd / noyau 4.9 | **ouverte** (bloquante) |

## Modèle

```markdown
# NNNN — Titre

## Contexte
## Décision
## Alternatives considérées
## Conséquences
## Références
```
