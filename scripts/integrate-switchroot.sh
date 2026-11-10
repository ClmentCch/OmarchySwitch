#!/usr/bin/env bash
#
# integrate-switchroot.sh — integrate Switchroot hardware components into the
# OmarchySwitch root filesystem and build the FAT boot tree hekate reads.
#
# Nothing is downloaded here. You provide the Switchroot files (see
# switchroot/README.md); this script:
#   1. reads switchroot/manifest.toml (declared components) and
#      switchroot/manifest.local.toml (your measured hashes, gitignored),
#   2. verifies every file against its SHA-256 before copying,
#   3. copies boot components into the FAT staging tree at
#      build/output/boot/switchroot/omarchyswitch/,
#   4. copies rootfs components (modules, firmware) into the rootfs,
#   5. writes a provenance file into the rootfs,
#   6. verifies that kernel, modules and firmware versions agree.
#
# Refusing unverified files is deliberate: a mismatched kernel/module pair
# produces a Switch that boots to a black screen with no way to read why.
#
# Usage:
#   sudo ./scripts/integrate-switchroot.sh --rootfs build/output/rootfs [options]
#
# Options:
#   --rootfs DIR          Prepared rootfs from build-rootfs.sh.
#   --boot-tree DIR      FAT staging tree (default build/output/boot).
#   --allow-unverified   Copy files whose SHA-256 is unknown (debug only).
#   --no-boot-tree       Only integrate rootfs components.
#   --dry-run            Print what would happen, copy nothing.
#   --yes                Non-interactive confirmation.
#   -h, --help           This help.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ROOTFS=""
BOOT_TREE=""
ALLOW_UNVERIFIED=0
DO_BOOT_TREE=1
DRY_RUN=0

usage() { sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --rootfs) ROOTFS="${2:-}"; [[ -n "$ROOTFS" ]] || osw_die "--rootfs needs a directory"; shift ;;
    --boot-tree) BOOT_TREE="${2:-}"; [[ -n "$BOOT_TREE" ]] || osw_die "--boot-tree needs a directory"; shift ;;
    --allow-unverified) ALLOW_UNVERIFIED=1 ;;
    --no-boot-tree) DO_BOOT_TREE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) export OSW_ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config
osw_require_root
[[ -n "$ROOTFS" ]] || osw_die "--rootfs is required"
ROOTFS="$(realpath -m -- "$ROOTFS")"
osw_require_dir "$ROOTFS"
osw_require_aarch64_tree "$ROOTFS"
BOOT_TREE="${BOOT_TREE:-$(osw_boot_tree)}"
BOOT_TREE="$(realpath -m -- "$BOOT_TREE")"

MANIFEST="$OSW_ROOT/$SWITCHROOT_MANIFEST"
LOCAL_MANIFEST="$OSW_ROOT/switchroot/manifest.local.toml"
SRC_ROOT="$OSW_ROOT/switchroot"
BOOT_PREFIX="${SWITCHROOT_BOOT_PREFIX:-/switchroot/omarchyswitch}"
BOOT_PREFIX="${BOOT_PREFIX%/}"

osw_start_log "integrate-switchroot"

osw_require_file "$MANIFEST"
osw_require_cmds python3 sha256sum

osw_step "Manifest"
osw_info "declared components: $MANIFEST"
if [[ -f "$LOCAL_MANIFEST" ]]; then
  osw_ok "measured hashes: $LOCAL_MANIFEST"
else
  osw_warn "no switchroot/manifest.local.toml: every hash will be considered unknown"
fi

# Merge declared hashes with locally measured ones (local wins).
merge_hashes() {
  python3 - "$MANIFEST" "$LOCAL_MANIFEST" <<'PY'
import sys, tomllib, pathlib

def load(path):
    p = pathlib.Path(path)
    if not p.exists():
        return {}
    with p.open("rb") as fh:
        data = tomllib.load(fh)
    out = {}
    for comp in data.get("component", []):
        for entry in comp.get("files", []) or [{"name": ""}]:
            key = (comp["id"], entry.get("name", ""))
            out[key] = {
                "sha256": entry.get("sha256", ""),
                "bytes": entry.get("bytes", 0),
            }
        if comp.get("mode") == "tree":
            out[(comp["id"], "")] = {
                "sha256": comp.get("tree_sha256", ""),
                "bytes": comp.get("tree_bytes", 0),
            }
    return out

declared = load(sys.argv[1])
local = load(sys.argv[2]) if len(sys.argv) > 2 else {}
for key, val in local.items():
    if val.get("sha256"):
        declared[key] = val
for (cid, name), val in declared.items():
    print("\t".join([cid, name, val["sha256"], str(val["bytes"])]))
PY
}

osw_step "Component verification"
merged_rows="$(merge_hashes)"
declare -A KNOWN_SHA=()
declare -A KNOWN_BYTES=()
while IFS=$'\t' read -r cid name sha bytes; do
  [[ -n "$cid" ]] || continue
  KNOWN_SHA["$cid|$name"]="$sha"
  KNOWN_BYTES["$cid|$name"]="$bytes"
done <<<"$merged_rows"

rows="$(osw_toml_rows "$MANIFEST")"
(( ${#rows} > 0 )) || osw_die "manifest declares no components"

declare -A SEEN=()
missing=0
unverified=0
while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
  [[ -n "$cid" ]] || continue
  src_path="$SRC_ROOT/$source_dir"
  if [[ "$mode" == "tree" ]]; then
    if [[ ! -d "$src_path" ]] || osw_dir_is_empty "$src_path"; then
      osw_error "$cid: missing directory $src_path"
      missing=$((missing + 1))
      continue
    fi
    key="$cid|"
  else
    [[ -n "$name" ]] || continue
    if [[ ! -f "$src_path/$name" ]]; then
      osw_error "$cid: missing file $src_path/$name"
      missing=$((missing + 1))
      continue
    fi
    key="$cid|$name"
  fi

  declared_sha="${KNOWN_SHA[$key]:-}"
  if [[ -z "$declared_sha" ]]; then
    unverified=$((unverified + 1))
    osw_warn "$cid${name:+ ($name)}: no SHA-256 on record"
    continue
  fi
  if [[ "$mode" == "tree" ]]; then
    actual="$(osw_sha256 "$src_path")"
  else
    actual="$(osw_sha256 "$src_path/$name")"
  fi
  if [[ "$actual" != "$declared_sha" ]]; then
    osw_error "$cid${name:+ ($name)}: SHA-256 mismatch
  declared: $declared_sha
  actual:   $actual"
    missing=$((missing + 1))
    continue
  fi
  SEEN["$key"]=1
  osw_ok "$cid${name:+ ($name)}: verified"
done <<<"$rows"

if (( missing > 0 )); then
  osw_die "$missing component file(s) missing or not matching.
Read switchroot/README.md, then import your files with:
  ./switchroot/scripts/import-components.sh --from /path/to/extracted-files
That script records SHA-256 values in switchroot/manifest.local.toml."
fi
if (( unverified > 0 )); then
  if (( ALLOW_UNVERIFIED )); then
    osw_warn "$unverified unverified file(s): copying because --allow-unverified was given"
  else
    osw_die "$unverified file(s) have no SHA-256 on record. Refusing to copy them.
Use ./switchroot/scripts/import-components.sh to measure and record them, or
pass --allow-unverified for a debug build you will not distribute."
  fi
fi

# --- Boot tree -------------------------------------------------------------
if (( DO_BOOT_TREE )); then
  osw_step "Boot tree ($BOOT_TREE)"
  if (( DRY_RUN )); then
    osw_info "dry run: would populate $BOOT_TREE$BOOT_PREFIX"
  else
    osw_ensure_dir "$BOOT_TREE$BOOT_PREFIX"
    osw_ensure_dir "$BOOT_TREE/bootloader/ini"

    # hekate entries from the repository
    if [[ -f "$OSW_ROOT/bootloader/hekate_ipl.ini" ]]; then
      install -Dm644 "$OSW_ROOT/bootloader/hekate_ipl.ini" "$BOOT_TREE/bootloader/hekate_ipl.ini"
      osw_ok "bootloader/hekate_ipl.ini"
    else
      osw_die "missing bootloader/hekate_ipl.ini"
    fi
    for ini in "$OSW_ROOT"/bootloader/configs/*.ini; do
      [[ -f "$ini" ]] || continue
      install -Dm644 "$ini" "$BOOT_TREE/bootloader/ini/$(basename "$ini")"
      osw_ok "bootloader/ini/$(basename "$ini")"
    done

    while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
      [[ "$target" == "boot" ]] || continue
      src_path="$SRC_ROOT/$source_dir"
      dest_path="$BOOT_TREE${dest_dir%/}"
      if [[ "$mode" == "tree" ]]; then
        osw_copy "$src_path/." "$dest_path/"
        osw_ok "boot: $cid (tree) -> $dest_path"
      else
        [[ -n "$name" ]] || continue
        install -Dm644 "$src_path/$name" "$dest_path/$name"
        osw_ok "boot: $name -> $dest_path/$name"
      fi
    done <<<"$rows"
  fi
else
  osw_warn "--no-boot-tree: skipping FAT staging tree"
fi

# --- Rootfs ----------------------------------------------------------------
osw_step "Rootfs components"
declare -A MODULE_TREES=()
while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
  [[ "$target" == "rootfs" ]] || continue
  src_path="$SRC_ROOT/$source_dir"
  dest_path="$ROOTFS${dest_dir}"
  if (( DRY_RUN )); then
    osw_info "dry run: $cid -> $dest_path"
    continue
  fi
  osw_ensure_dir "$dest_path"
  if [[ "$mode" == "tree" ]]; then
    osw_info "copying $cid (tree) into $dest_path"
    cp -a -- "$src_path/." "$dest_path/"
    osw_ok "$cid -> $dest_path"
    if [[ "$cid" == "modules" ]]; then MODULE_TREES["$dest_path"]=1; fi
  else
    [[ -n "$name" ]] || continue
    install -Dm644 "$src_path/$name" "$dest_path/$name"
    osw_ok "$name -> $dest_path/$name"
  fi
done <<<"$rows"

if (( DRY_RUN )); then
  osw_ok "dry run finished"
  exit 0
fi

# --- Consistency checks ----------------------------------------------------
osw_step "Kernel / modules / firmware consistency"
kernel_image=""
for candidate in "$BOOT_TREE$BOOT_PREFIX/uImage" "$ROOTFS$BOOT_PREFIX/uImage"; do
  [[ -f "$candidate" ]] && kernel_image="$candidate" && break
done
if [[ -n "$kernel_image" ]]; then
  # U-Boot uImage header: 64-byte header, 'Linux' name at offset 32.
  kernel_name="$(dd if="$kernel_image" bs=1 skip=32 count=32 2>/dev/null | tr -d '\0')"
  osw_info "uImage name field: ${kernel_name:-<unknown>}"
else
  osw_warn "no uImage found in the staging tree or rootfs"
fi

if [[ -d "$ROOTFS/usr/lib/modules" ]]; then
  mapfile -t module_dirs < <(find "$ROOTFS/usr/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  if (( ${#module_dirs[@]} == 0 )); then
    osw_warn "no kernel modules installed: Wi-Fi, Bluetooth, audio and Joy-Con will not work"
  else
    osw_ok "kernel module trees: ${module_dirs[*]}"
    if [[ -n "${L4T_KERNEL_VERSION:-}" ]]; then
      match=0
      for v in "${module_dirs[@]}"; do
        [[ "$v" == "$L4T_KERNEL_VERSION"* ]] && match=1
      done
      if (( match == 1 )); then
        osw_ok "module tree matches expected L4T kernel $L4T_KERNEL_VERSION"
      else
        osw_warn "no module tree matches $L4T_KERNEL_VERSION; kernel and modules probably disagree"
      fi
    fi
  fi
else
  osw_warn "no /usr/lib/modules in the rootfs"
fi

if [[ -d "$ROOTFS/lib/firmware" ]]; then
  fw_count="$(find "$ROOTFS/lib/firmware" -type f 2>/dev/null | wc -l | tr -d ' ')"
  osw_ok "firmware files: $fw_count"
  for fw in brcmfmac4356-pcie.bin brcmfmac4356-pcie.txt; do
    if find "$ROOTFS/lib/firmware" -name "$fw" -print -quit 2>/dev/null | grep -q .; then
      osw_ok "firmware present: $fw (Wi-Fi)"
    else
      osw_warn "firmware missing: $fw (Wi-Fi will not work)"
    fi
  done
else
  osw_warn "no /lib/firmware in the rootfs"
fi

# --- Provenance ------------------------------------------------------------
osw_step "Provenance"
PROV_DIR="$ROOTFS/etc/omarchyswitch"
osw_ensure_dir "$PROV_DIR"
{
  printf '# OmarchySwitch - Switchroot component provenance\n'
  printf '# Generated by integrate-switchroot.sh. Do not edit by hand.\n'
  printf 'generated_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'manifest=%s\n' "$SWITCHROOT_MANIFEST"
  printf 'boot_prefix=%s\n' "$BOOT_PREFIX"
  while IFS=$'\t' read -r cid mode target dest_dir source_dir required name sha bytes; do
    [[ -n "$cid" ]] || continue
    key="$cid|$name"
    printf 'component=%s file=%s sha256=%s target=%s\n' \
      "$cid" "${name:-<tree>}" "${KNOWN_SHA[$key]:-unverified}" "$target"
  done <<<"$rows"
} > "$PROV_DIR/switchroot-provenance.txt"
osw_ok "$PROV_DIR/switchroot-provenance.txt"

# Marker the Switchroot initramfs looks for.
if [[ ! -f "$ROOTFS/etc/switchroot_version.conf" ]]; then
  printf 'switchroot_version=%s\n' "$SWITCHROOT_VERSION_FILE_VALUE" > "$ROOTFS/etc/switchroot_version.conf"
  osw_ok "created /etc/switchroot_version.conf"
fi

cat >&2 <<EOF

Switchroot components integrated.
  rootfs:    $ROOTFS
  boot tree: $BOOT_TREE (copy its contents to the FAT partition)

Next:
  sudo ./scripts/integrate-omarchy.sh --rootfs "$ROOTFS"
EOF
osw_ok "integrate-switchroot finished"
