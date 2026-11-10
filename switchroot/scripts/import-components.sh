#!/usr/bin/env bash
#
# import-components.sh — copy Switchroot components into switchroot/ and record
# their SHA-256 so the build can verify them.
#
# It does not download anything: you provide a directory that already contains
# the files (extracted Release archive, compiled kernel, copied modules and
# firmware). See switchroot/README.md for where each file comes from.
#
# Recognised layouts under --from:
#   <from>/kernel/uImage            or <from>/uImage
#   <from>/dtb/nx-plat.dtimg        or <from>/nx-plat.dtimg
#   <from>/boot/{initramfs,boot.scr,bl31.bin,bl33.bin}
#   <from>/modules/<version>/...    or <from>/modules (already a module tree)
#   <from>/firmware/...
#
# Results:
#   switchroot/<component dir>/...        copied files
#   switchroot/manifest.local.toml        measured SHA-256 (gitignored)
#
# Usage:
#   ./switchroot/scripts/import-components.sh --from DIR [--dry-run] [--list-missing]
#
# Exit codes: 0 success, 1 failure, 2 usage error.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"

FROM=""
DRY_RUN=0
LIST_MISSING=0

usage() { sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --from) FROM="${2:-}"; [[ -n "$FROM" ]] || osw_die "--from needs a directory"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --list-missing) LIST_MISSING=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_cmds python3 sha256sum

MANIFEST="$OSW_ROOT/$SWITCHROOT_MANIFEST"
LOCAL_MANIFEST="$OSW_ROOT/switchroot/manifest.local.toml"
SRC_ROOT="$OSW_ROOT/switchroot"

osw_require_file "$MANIFEST"

rows="$(osw_toml_rows "$MANIFEST")"
(( ${#rows} > 0 )) || osw_die "manifest declares no components"

if (( LIST_MISSING )); then
  osw_step "Component status"
  missing=0
  while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
    [[ -n "$cid" ]] || continue
    src_path="$SRC_ROOT/$source_dir"
    if [[ "$mode" == "tree" ]]; then
      if [[ -d "$src_path" ]] && ! osw_dir_is_empty "$src_path"; then
        osw_ok "$cid: directory present ($(du -sh "$src_path" | awk '{print $1}'))"
      else
        osw_error "$cid: missing or empty directory $src_path"
        missing=$((missing + 1))
      fi
    else
      if [[ -f "$src_path/$name" ]]; then
        osw_ok "$cid: $name present ($(osw_file_bytes "$src_path/$name") bytes)"
      else
        osw_error "$cid: missing $src_path/$name"
        missing=$((missing + 1))
      fi
    fi
  done <<<"$rows"
  if (( missing > 0 )); then
    osw_warn "$missing component(s) missing — see switchroot/README.md"
    exit 1
  fi
  osw_ok "all declared components present"
  exit 0
fi

[[ -n "$FROM" ]] || osw_die "--from is required (use --list-missing to inspect without importing)"
FROM="$(realpath -m -- "$FROM")"
osw_require_dir "$FROM"

# Locate a component source: prefer the structured layout, fall back to flat.
locate_file() {
  local source_dir="$1" name="$2"
  local candidate
  for candidate in "$FROM/$source_dir/$name" "$FROM/$name"; do
    if [[ -f "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

locate_tree() {
  local source_dir="$1" cid="$2"
  local candidate
  for candidate in "$FROM/$source_dir" "$FROM/$cid"; do
    if [[ -d "$candidate" ]] && ! osw_dir_is_empty "$candidate"; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

osw_step "Importing components from $FROM"
imported=0
unresolved=0
ROWS_FILE="$(osw_tmpdir)/measured.tsv"
: > "$ROWS_FILE"

while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
  [[ -n "$cid" ]] || continue
  dest_dir_path="$SRC_ROOT/$source_dir"

  if [[ "$mode" == "tree" ]]; then
    if ! src="$(locate_tree "$source_dir" "$cid")"; then
      osw_error "$cid: no directory found (looked for $FROM/$source_dir and $FROM/$cid)"
      unresolved=$((unresolved + 1))
      continue
    fi
    digest="$(osw_sha256 "$src")"
    count="$(find "$src" -type f | wc -l | tr -d ' ')"
    size="$(du -sb "$src" | awk '{print $1}')"
    osw_info "$cid: $count files, $size bytes, tree sha256 $digest"
    if (( ! DRY_RUN )); then
      osw_ensure_dir "$dest_dir_path"
      cp -a -- "$src/." "$dest_dir_path/"
      printf 'tree\t%s\t%s\t%s\t%s\n' "$cid" "" "$digest" "$size" >> "$ROWS_FILE"
    fi
  else
    [[ -n "$name" ]] || continue
    if ! src="$(locate_file "$source_dir" "$name")"; then
      osw_error "$cid: no file named $name (looked in $FROM/$source_dir and $FROM)"
      unresolved=$((unresolved + 1))
      continue
    fi
    digest="$(osw_sha256 "$src")"
    size="$(osw_file_bytes "$src")"
    osw_info "$cid: $name ($size bytes) sha256 $digest"
    if (( ! DRY_RUN )); then
      install -Dm644 "$src" "$dest_dir_path/$name"
      printf 'file\t%s\t%s\t%s\t%s\n' "$cid" "$name" "$digest" "$size" >> "$ROWS_FILE"
    fi
  fi
  imported=$((imported + 1))
done <<<"$rows"

if (( DRY_RUN )); then
  osw_warn "dry run: nothing copied, no manifest written"
  exit 0
fi

if (( unresolved > 0 )); then
  osw_warn "$unresolved component(s) could not be resolved from $FROM"
  osw_info "Place them explicitly (see switchroot/README.md), then re-run:"
  osw_info "  ./switchroot/scripts/import-components.sh --from switchroot"
fi
(( imported > 0 )) || osw_die "nothing imported"

osw_step "Writing $LOCAL_MANIFEST"
python3 - "$LOCAL_MANIFEST" "$ROWS_FILE" "$DISTRO_VERSION" <<'PY'
import sys, pathlib, datetime, collections

out_path = pathlib.Path(sys.argv[1])
rows_path = pathlib.Path(sys.argv[2])
version = sys.argv[3]

entries = collections.OrderedDict()
for line in rows_path.read_text().splitlines():
    parts = line.split("\t")
    if len(parts) != 5:
        continue
    mode, cid, name, sha, size = parts
    entries.setdefault(cid, {"mode": mode, "files": [], "tree": None})
    if mode == "tree":
        entries[cid]["tree"] = {"sha256": sha, "bytes": int(size)}
    else:
        entries[cid]["files"].append({"name": name, "sha256": sha, "bytes": int(size)})

lines = [
    "# Generated by switchroot/scripts/import-components.sh — DO NOT COMMIT.",
    "# Measured SHA-256 values for locally supplied Switchroot components.",
    "",
    "[meta]",
    "schema = 1",
    f'generated_at = "{datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"',
    f'generator_version = "{version}"',
    "",
]
for cid, data in entries.items():
    lines.append("[[component]]")
    lines.append(f'id = "{cid}"')
    if data["tree"]:
        lines.append(f'tree_sha256 = "{data["tree"]["sha256"]}"')
        lines.append(f'tree_bytes = {data["tree"]["bytes"]}')
    for entry in data["files"]:
        lines.append(
            'files = [{ name = "%s", sha256 = "%s", bytes = %d }]'
            % (entry["name"], entry["sha256"], entry["bytes"])
        )
    lines.append("")

out_path.write_text("\n".join(lines))
print(f"wrote {len(entries)} component entries", file=sys.stderr)
PY

chmod 644 "$LOCAL_MANIFEST"
osw_ok "$LOCAL_MANIFEST"

cat >&2 <<EOF

Imported $imported component(s) into switchroot/.

Next:
  ./switchroot/scripts/import-components.sh --list-missing
  sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs

Reminder: manifest.local.toml is gitignored and must never be published with
a release (it reveals local file hashes; the binaries themselves are not
redistributable).
EOF
osw_ok "import-components finished"
