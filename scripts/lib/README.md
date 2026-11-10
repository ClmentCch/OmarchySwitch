# `scripts/lib/` — bibliothèque commune

`common.sh` est sourcé par tous les scripts. Il ne s'exécute pas pour lui-même,
sauf pour `--print-config`.

## Ce qu'il fournit

| Groupe | Fonctions |
|---|---|
| Journalisation | `osw_info`, `osw_ok`, `osw_warn`, `osw_error`, `osw_die`, `osw_step`, `osw_debug` |
| Configuration | `osw_load_config`, `osw_print_config` |
| Préconditions | `osw_require_cmds`, `osw_require_root`, `osw_require_file`, `osw_require_dir`, `osw_confirm` |
| Architecture | `osw_require_target_arch`, `osw_is_aarch64_elf`, `osw_elf_machine`, `osw_require_aarch64_tree`, `osw_assert_no_foreign_elf` |
| Fichiers | `osw_sha256` (fichier et arborescence), `osw_file_bytes`, `osw_dir_is_empty`, `osw_require_empty_or_absent`, `osw_require_free_space` |
| Build | `osw_boot_tree`, `osw_start_log`, `osw_run_logged`, `osw_check_binfmt` |
| Manifests | `osw_toml_rows` (TOML → TSV via `python3 -m tomllib`) |
| Temporaires | `osw_tmpdir`, `osw_cleanup` (trap EXIT) |

## Détection d'architecture

`osw_is_aarch64_elf` lit l'en-tête ELF directement (`od`), sans dépendre de
`file` : il fonctionne sur n'importe quel hôte, y compris minimal. `e_machine`
est comparé à `0xb7` (183, AArch64).

`osw_assert_no_foreign_elf` échantillonne les exécutables d'un rootfs et échoue
si un binaire non-aarch64 est trouvé. C'est le garde-fou contre un tarball ou un
paquet de mauvaise architecture.

## Pourquoi `set -euo pipefail` et des fonctions explicites

Les scripts manipulent des chemins, des empreintes et parfois des partitions. Une
variable non définie ou un échec masqué y coûte cher. La bibliothèque impose donc
`-u` et `pipefail`, et évite les `$(...)` non vérifiés.

## Utilisation

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

osw_load_config
osw_require_root
osw_confirm "Continuer ?"
```
