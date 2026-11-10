#!/usr/bin/env bash
#
# validate-architecture.sh — static consistency checks for the OmarchySwitch
# repository. No root, no network, no side effects.
#
# What is checked:
#   structure      required directories, README files, required files
#   scripts        shebang, executable bit, bash -n, shellcheck (if installed)
#   architecture   aarch64-only policy: no x86_64 packages, no foreign ELF
#   configuration  configs/*.conf keys, labels, referenced paths
#   bootloader     ini syntax and mandatory hekate L4T keys
#   manifests      TOML parse and schema (switchroot, hardware, applications)
#   branding       os-release, VERSION, CHANGELOG consistency
#   hygiene        no secrets, no oversized files, no binaries, no empty files
#   docs           relative Markdown links resolve
#
# Exit codes: 0 all checks pass, 1 at least one failure, 2 usage error.
#
# Usage:
#   ./scripts/validate-architecture.sh [--quiet] [--no-shellcheck] [--list]

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

QUIET=0
USE_SHELLCHECK=1
LIST_ONLY=0

usage() { sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --quiet|-q) QUIET=1 ;;
    --no-shellcheck) USE_SHELLCHECK=0 ;;
    --list) LIST_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; osw_die "unknown argument: $1" ;;
  esac
  shift
done

osw_load_config

PASS=0
FAIL=0
WARN=0
declare -a FAILURES=()

pass() { PASS=$((PASS + 1)); if (( QUIET == 0 )); then printf '  %s✓%s %s\n' "$_osw_c_green" "$_osw_c_reset" "$*"; fi; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$*"); printf '  %s✗%s %s\n' "$_osw_c_red" "$_osw_c_reset" "$*" >&2; }
warn() { WARN=$((WARN + 1)); if (( QUIET == 0 )); then printf '  %s!%s %s\n' "$_osw_c_yellow" "$_osw_c_reset" "$*"; fi; }
section() { if (( QUIET == 0 )); then printf '\n%s%s%s\n' "$_osw_c_bold" "$*" "$_osw_c_reset"; fi; }

CHECKS=(
  "structure:required paths and README files"
  "scripts:shebang, permissions, syntax, shellcheck"
  "architecture:aarch64-only policy"
  "configuration:consistency of configs/*.conf"
  "bootloader:hekate ini syntax and L4T keys"
  "manifests:TOML schema of manifests"
  "branding:os-release, VERSION, CHANGELOG"
  "hygiene:secrets, large files, binaries, empty files"
  "docs:relative Markdown links"
)

if (( LIST_ONLY )); then
  printf '%s\n' "${CHECKS[@]}"
  exit 0
fi

cd -- "$OSW_ROOT"

# ---------------------------------------------------------------------------
section "structure"

REQUIRED_DIRS=(
  bootloader bootloader/configs bootloader/scripts
  switchroot switchroot/kernel switchroot/dtb switchroot/modules
  switchroot/firmware switchroot/boot switchroot/drivers switchroot/scripts
  archlinux archlinux/bootstrap archlinux/pacman archlinux/rootfs
  archlinux/rootfs/firstboot archlinux/rootfs/overlay archlinux/packages
  hardware hardware/aarch64-tegra-x1
  hardware/aarch64-tegra-x1/display hardware/aarch64-tegra-x1/gpu
  hardware/aarch64-tegra-x1/audio hardware/aarch64-tegra-x1/joycon
  hardware/aarch64-tegra-x1/wifi hardware/aarch64-tegra-x1/bluetooth
  hardware/aarch64-tegra-x1/touchscreen hardware/aarch64-tegra-x1/storage
  hardware/aarch64-tegra-x1/power
  omarchy omarchy/upstream omarchy/patches omarchy/configs omarchy/scripts
  desktop desktop/hyprland desktop/waybar desktop/walker desktop/terminal
  desktop/themes desktop/fonts
  applications applications/switchroot applications/system
  installer installer/scripts installer/partition installer/rootfs
  recovery recovery/diagnostics recovery/restore
  build build/scripts build/configs build/manifests
  configs scripts scripts/lib docs docs/adr docs/research
  .github/workflows
)
for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then pass "directory $dir/"; else fail "missing directory: $dir/"; fi
done

REQUIRED_READMES=(
  bootloader bootloader/configs bootloader/scripts
  switchroot switchroot/kernel switchroot/dtb switchroot/modules
  switchroot/firmware switchroot/boot switchroot/drivers switchroot/scripts
  archlinux archlinux/bootstrap archlinux/pacman archlinux/rootfs
  archlinux/rootfs/firstboot archlinux/packages
  hardware/aarch64-tegra-x1 hardware/aarch64-tegra-x1/display
  hardware/aarch64-tegra-x1/gpu hardware/aarch64-tegra-x1/audio
  hardware/aarch64-tegra-x1/joycon hardware/aarch64-tegra-x1/wifi
  hardware/aarch64-tegra-x1/bluetooth hardware/aarch64-tegra-x1/touchscreen
  hardware/aarch64-tegra-x1/storage hardware/aarch64-tegra-x1/power
  omarchy omarchy/upstream omarchy/patches omarchy/configs omarchy/scripts
  desktop desktop/hyprland desktop/waybar desktop/walker desktop/terminal
  desktop/themes desktop/fonts
  applications applications/switchroot applications/system
  installer installer/scripts installer/partition installer/rootfs
  recovery recovery/diagnostics recovery/restore
  build build/scripts build/configs build/manifests
  configs scripts scripts/lib docs docs/adr docs/research
  .github/workflows
)
for dir in "${REQUIRED_READMES[@]}"; do
  if [[ -f "$dir/README.md" ]]; then pass "README in $dir/"; else fail "missing $dir/README.md"; fi
done

REQUIRED_FILES=(
  README.md LICENSE CONTRIBUTING.md CHANGELOG.md VERSION THIRD-PARTY.md Makefile
  .gitignore .gitattributes .github/workflows/build.yml
  configs/omarchyswitch.conf configs/versions.lock
  scripts/lib/common.sh scripts/bootstrap-arch.sh scripts/build-rootfs.sh
  scripts/integrate-switchroot.sh scripts/integrate-omarchy.sh
  scripts/install-desktop.sh scripts/validate-architecture.sh
  scripts/build-image.sh scripts/package-release.sh
  bootloader/hekate_ipl.ini bootloader/configs/omarchyswitch-erista.ini
  bootloader/scripts/install-bootfiles.sh
  switchroot/manifest.toml switchroot/scripts/import-components.sh
  archlinux/pacman/pacman.conf archlinux/pacman/mirrorlist
  archlinux/rootfs/overlay/etc/os-release
  archlinux/rootfs/overlay/etc/fstab.template
  archlinux/rootfs/overlay/etc/switchroot_version.conf
  archlinux/rootfs/firstboot/omarchyswitch-firstboot.sh
  archlinux/packages/omarchyswitch-base/PKGBUILD
  archlinux/packages/linux-switchroot/PKGBUILD
  hardware/aarch64-tegra-x1/features.toml
  omarchy/configs/hypr/omarchyswitch.conf
  omarchy/configs/environment.d/10-omarchyswitch.conf
  omarchy/scripts/apply-configs.sh omarchy/patches/series
  desktop/waybar/config.switch.jsonc desktop/fonts/packages.txt
  applications/switchroot/manifest.toml applications/system/packages.txt
  installer/scripts/install.sh installer/partition/partition-sd.sh
  recovery/diagnostics/collect.sh recovery/restore/restore-bootfiles.sh
  build/scripts/build-all.sh build/scripts/fetch-upstreams.sh
  build/configs/ci.env build/manifests/base-packages.txt
  build/manifests/omarchy-packages.txt build/manifests/desktop-packages.txt
  build/manifests/runtime-files.toml
  docs/00-overview.md docs/01-architecture.md docs/02-boot-chain.md
  docs/03-build.md docs/04-installation.md docs/05-status-matrix.md
  docs/06-known-limitations.md docs/07-upstream-sources.md docs/08-packaging.md
  docs/09-remaining-work.md docs/10-testing.md docs/11-roadmap.md
  docs/12-glossary.md
  docs/adr/0001-arch-linux-arm-base.md docs/adr/0002-hekate-l4t-boot-chain.md
  docs/adr/0003-no-vendored-binaries.md
  docs/adr/0004-systemd-kernel-compatibility.md
  docs/research/omarchy-4.5.0.md docs/research/switchroot-erista.md
)
for file in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$file" ]]; then pass "file $file"; else fail "missing file: $file"; fi
done

# ---------------------------------------------------------------------------
section "scripts"

mapfile -t SHELL_SCRIPTS < <(find . -name '*.sh' -not -path './.git/*' -not -path './dist/*' -not -path './build/output/*' | sort)
if (( ${#SHELL_SCRIPTS[@]} > 0 )); then
  pass "${#SHELL_SCRIPTS[@]} shell scripts found"
else
  fail "no shell scripts found"
fi

syntax_errors=0
for script in "${SHELL_SCRIPTS[@]}"; do
  if ! head -n1 "$script" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash'; then
    fail "missing or wrong shebang: $script"
  fi
  if [[ ! -x "$script" ]]; then
    fail "not executable: $script (chmod +x)"
  fi
  if ! bash -n "$script" 2>/tmp/osw-syntax.err; then
    fail "bash syntax error in $script: $(tr '\n' ' ' </tmp/osw-syntax.err)"
    syntax_errors=$((syntax_errors + 1))
  fi
done
if (( syntax_errors == 0 )); then
  pass "bash -n passed for every script"
fi

if (( USE_SHELLCHECK )); then
  if osw_have shellcheck; then
    # Severity "error" only: configuration variables are sourced at runtime
    # from configs/*.conf, which shellcheck cannot follow (SC2154 is expected
    # and not a defect). Real problems (SC1xxx parsing, SC2xxx misuse at error
    # level) still fail.
    if shellcheck -x -S error -e SC1091 "${SHELL_SCRIPTS[@]}" >/tmp/osw-shellcheck.out 2>&1; then
      pass "shellcheck (errors) clean: $(shellcheck --version | awk '/version:/ {print $2}')"
    else
      fail "shellcheck errors:"
      sed 's/^/      /' /tmp/osw-shellcheck.out >&2
    fi
  else
    warn "shellcheck not installed: skipped (CI installs it)"
  fi
fi

# ---------------------------------------------------------------------------
section "architecture"

osw_require_target_arch
pass "TARGET_ARCH=$TARGET_ARCH"

pkgbuild_hits="$(grep -rn --include='PKGBUILD' -E "arch=\([^)]*(x86_64|i686|armv7)" . 2>/dev/null || true)"
if [[ -n "$pkgbuild_hits" ]]; then
  fail "PKGBUILD declares a non-aarch64 architecture: $pkgbuild_hits"
else
  pass "PKGBUILDs declare aarch64 or any"
fi

bad_pacman=0
while IFS= read -r line; do
  if [[ "$line" =~ pacman.*--arch[=\ ]+(x86_64|i686|armv7) ]]; then
    fail "pacman invoked with a foreign architecture: $line"
    bad_pacman=$((bad_pacman + 1))
  fi
done < <(grep -rn --include='*.sh' 'pacman' scripts installer build switchroot archlinux 2>/dev/null || true)
if (( bad_pacman == 0 )); then
  pass "no foreign-architecture pacman invocation"
fi

bad_elf=0
while IFS= read -r -d '' candidate; do
  magic="$(od -An -tx1 -N4 "$candidate" 2>/dev/null | tr -d ' \n')"
  if [[ "$magic" == "7f454c46" ]]; then
    fail "committed ELF binary: ${candidate#./} ($(osw_elf_machine "$candidate"))"
    bad_elf=$((bad_elf + 1))
  fi
done < <(find . -type f -not -path './.git/*' -not -path './dist/*' -not -path './build/*' -size +0 -print0)
if (( bad_elf == 0 )); then
  pass "no ELF binaries committed"
fi

if (( ${#ROOT_FS_LABEL} <= 7 )); then
  pass "ROOT_FS_LABEL '$ROOT_FS_LABEL' fits hekate id= (<= 7 chars)"
else
  fail "ROOT_FS_LABEL '$ROOT_FS_LABEL' is longer than hekate's 7-char id= limit"
fi

if (( ${#BOOT_FS_LABEL} <= 11 )); then
  pass "BOOT_FS_LABEL '$BOOT_FS_LABEL' fits the FAT32 11-character label limit"
else
  fail "BOOT_FS_LABEL '$BOOT_FS_LABEL' exceeds the FAT32 11-character limit"
fi

# ---------------------------------------------------------------------------
section "configuration"

for var in DISTRO_NAME DISTRO_ID DISTRO_VERSION TARGET_ARCH ALARM_TARBALL_URL \
           OMARCHY_TAG OMARCHY_PKG_REPO_STABLE HEKATE_VERSION SWITCHROOT_MANIFEST \
           BOOT_FS_LABEL ROOT_FS_LABEL SWITCHROOT_BOOT_PREFIX L4T_KERNEL_VERSION; do
  if [[ -n "${!var:-}" ]]; then pass "config $var is set"; else fail "config $var is empty"; fi
done

for path in "$ALARM_PACMAN_CONF" "$ALARM_MIRRORLIST" "$SWITCHROOT_MANIFEST"; do
  if [[ -f "$path" ]]; then pass "referenced path exists: $path"; else fail "referenced path missing: $path"; fi
done

if [[ "$SWITCHROOT_BOOT_PREFIX" == /switchroot/* ]]; then
  pass "boot prefix is under /switchroot/: $SWITCHROOT_BOOT_PREFIX"
else
  fail "boot prefix must live under /switchroot/ (got $SWITCHROOT_BOOT_PREFIX)"
fi

if grep -q '^Architecture = aarch64' archlinux/pacman/pacman.conf; then
  pass "pacman.conf pins Architecture = aarch64"
else
  fail "archlinux/pacman/pacman.conf must contain 'Architecture = aarch64'"
fi

if grep -qE '^\[core\]' archlinux/pacman/pacman.conf && grep -qE '^\[alarm\]' archlinux/pacman/pacman.conf; then
  pass "pacman.conf declares core and alarm repositories"
else
  fail "pacman.conf must declare [core] and [alarm] repositories"
fi

if grep -q 'omarchy' build/manifests/omarchy-packages.txt; then
  block="$(grep -nE '^[^#]*linux-omarchy' build/manifests/omarchy-packages.txt || true)"
  if [[ -n "$block" ]]; then
    fail "linux-omarchy must never be installed on Tegra X1: $block"
  else
    pass "omarchy-packages.txt does not pull linux-omarchy"
  fi
else
  fail "build/manifests/omarchy-packages.txt declares no omarchy package"
fi

# ---------------------------------------------------------------------------
section "bootloader"

INI_FILES=(bootloader/hekate_ipl.ini)
while IFS= read -r -d '' ini; do INI_FILES+=("$ini"); done < <(find bootloader/configs -name '*.ini' -print0 | sort -z)

for ini in "${INI_FILES[@]}"; do
  if [[ ! -f "$ini" ]]; then fail "missing ini: $ini"; continue; fi
  if python3 - "$ini" <<'PY'
import sys
path = sys.argv[1]
section = None
for lineno, raw in enumerate(open(path, encoding="utf-8"), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("[") and line.endswith("]"):
        section = line[1:-1]
        if not section.strip():
            sys.exit(f"{path}:{lineno}: empty section name")
        continue
    if section is None:
        sys.exit(f"{path}:{lineno}: key outside a section: {line}")
    if "=" not in line:
        sys.exit(f"{path}:{lineno}: not a key=value line: {line}")
    key = line.split("=", 1)[0]
    if not key.strip():
        sys.exit(f"{path}:{lineno}: empty key")
PY
  then
    pass "ini syntax ok: $ini"
  else
    fail "ini syntax error in $ini"
  fi

  if grep -q '^l4t=1' "$ini"; then
    if grep -qE '^boot_prefixes=/switchroot/' "$ini"; then
      pass "L4T entry with boot_prefixes in $ini"
    else
      fail "$ini declares l4t=1 without a /switchroot/ boot_prefixes"
    fi
    while IFS= read -r idline; do
      idval="${idline#id=}"
      if (( ${#idval} > 7 )); then
        fail "$ini: id='$idval' exceeds hekate's 7-character limit"
      fi
    done < <(grep -E '^id=' "$ini" || true)
  fi
done

# ---------------------------------------------------------------------------
section "manifests"

if python3 - "$SWITCHROOT_MANIFEST" hardware/aarch64-tegra-x1/features.toml applications/switchroot/manifest.toml build/manifests/runtime-files.toml <<'PY'
import sys, tomllib, pathlib

errors = []

def load(path):
    p = pathlib.Path(path)
    if not p.exists():
        errors.append(f"missing manifest: {path}")
        return None
    try:
        with p.open("rb") as fh:
            return tomllib.load(fh)
    except Exception as exc:  # noqa: BLE001 - report any parse error
        errors.append(f"{path}: TOML parse error: {exc}")
        return None

def require(cond, message):
    if not cond:
        errors.append(message)

# --- switchroot manifest -------------------------------------------------
data = load(sys.argv[1])
if data is not None:
    require("meta" in data, "switchroot/manifest.toml: missing [meta]")
    meta = data.get("meta", {})
    require(meta.get("schema") == 1, "switchroot/manifest.toml: meta.schema must be 1")
    require(meta.get("target_family") == "erista",
            "switchroot/manifest.toml: meta.target_family must be 'erista'")
    comps = data.get("component", [])
    require(len(comps) >= 5, "switchroot/manifest.toml: expected at least 5 components")
    seen_ids = set()
    for comp in comps:
        cid = comp.get("id", "<unnamed>")
        require(cid not in seen_ids, f"switchroot/manifest.toml: duplicate component id '{cid}'")
        seen_ids.add(cid)
        for key in ("id", "label", "license", "upstream", "target", "dest_dir"):
            require(key in comp, f"switchroot/manifest.toml: component '{cid}' missing key '{key}'")
        require(comp.get("target") in ("boot", "rootfs"),
                f"switchroot/manifest.toml: component '{cid}' target must be boot or rootfs")
        require(comp.get("mode", "files") in ("files", "tree"),
                f"switchroot/manifest.toml: component '{cid}' mode must be files or tree")
        require(str(comp.get("dest_dir", "")).startswith("/"),
                f"switchroot/manifest.toml: component '{cid}' dest_dir must be absolute")
        if comp.get("mode", "files") == "files":
            require(bool(comp.get("files")),
                    f"switchroot/manifest.toml: component '{cid}' declares no files")
            for entry in comp.get("files", []):
                require("name" in entry,
                        f"switchroot/manifest.toml: component '{cid}' file without name")
                sha = entry.get("sha256", "")
                require(sha == "" or (len(sha) == 64 and all(c in "0123456789abcdef" for c in sha)),
                        f"switchroot/manifest.toml: component '{cid}' file '{entry.get('name')}' has an invalid sha256")
    for required_id in ("kernel", "dtb", "atf", "uboot", "modules", "firmware"):
        require(required_id in seen_ids,
                f"switchroot/manifest.toml: missing required component '{required_id}'")

# --- hardware features ---------------------------------------------------
data = load(sys.argv[2])
if data is not None:
    features = data.get("feature", [])
    require(len(features) >= 8, "hardware/aarch64-tegra-x1/features.toml: expected at least 8 features")
    allowed = {"fonctionnel", "prepare", "bloque", "a_tester", "non_supporte"}
    for feature in features:
        fid = feature.get("id", "<unnamed>")
        for key in ("id", "label", "status", "blocker"):
            require(key in feature, f"features.toml: feature '{fid}' missing key '{key}'")
        require(feature.get("status") in allowed,
                f"features.toml: feature '{fid}' has invalid status '{feature.get('status')}'")
    functional = [f for f in features if f.get("status") == "fonctionnel"]
    require(len(functional) == 0,
            "features.toml: no feature may be 'fonctionnel' until it is verified on hardware")

# --- applications manifest ----------------------------------------------
data = load(sys.argv[3])
if data is not None:
    apps = data.get("application", [])
    require(len(apps) >= 3, "applications/switchroot/manifest.toml: expected at least 3 applications")
    allowed = {"porte", "a_porter", "bloque", "remplace"}
    for app in apps:
        aid = app.get("id", "<unnamed>")
        for key in ("id", "label", "license", "status"):
            require(key in app, f"applications manifest: application '{aid}' missing key '{key}'")
        require(app.get("status") in allowed,
                f"applications manifest: application '{aid}' has invalid status '{app.get('status')}'")

# --- runtime file layout -------------------------------------------------
data = load(sys.argv[4])
if data is not None:
    entries = data.get("entry", [])
    require(len(entries) >= 10, "build/manifests/runtime-files.toml: expected at least 10 entries")
    for entry in entries:
        path = entry.get("path", "<unnamed>")
        require(path.startswith("/"), f"runtime-files.toml: entry '{path}' must be absolute")
        require("required" in entry, f"runtime-files.toml: entry '{path}' missing 'required'")

if errors:
    for message in errors:
        print(message)
    raise SystemExit(1)
PY
then
  pass "TOML manifests parse and match their schema"
else
  fail "manifest validation failed (see above)"
fi

# ---------------------------------------------------------------------------
section "branding"

os_release="archlinux/rootfs/overlay/etc/os-release"
if [[ -f "$os_release" ]]; then
  if grep -q "^ID=$DISTRO_ID" "$os_release"; then pass "os-release ID=$DISTRO_ID"; else fail "os-release ID does not match DISTRO_ID ($DISTRO_ID)"; fi
  if grep -q '^NAME=' "$os_release"; then pass "os-release NAME present"; else fail "os-release has no NAME"; fi
else
  fail "missing $os_release"
fi

file_version="$(tr -d '[:space:]' < VERSION)"
if [[ "$file_version" == "$DISTRO_VERSION" ]]; then
  pass "VERSION ($file_version) matches DISTRO_VERSION"
else
  fail "VERSION ($file_version) != DISTRO_VERSION ($DISTRO_VERSION)"
fi
if grep -q "^## \[$file_version\]" CHANGELOG.md; then
  pass "CHANGELOG has an entry for $file_version"
else
  fail "CHANGELOG has no '## [$file_version]' section"
fi
if grep -q "\"$OMARCHY_TAG\"" configs/versions.lock && grep -q "\"$OMARCHY_TAG\"" configs/omarchyswitch.conf; then
  pass "Omarchy tag pinned consistently ($OMARCHY_TAG)"
else
  fail "OMARCHY_TAG differs between configs/omarchyswitch.conf and configs/versions.lock"
fi

# ---------------------------------------------------------------------------
section "hygiene"

secret_hits=0
while IFS= read -r hit; do
  fail "possible secret: $hit"
  secret_hits=$((secret_hits + 1))
done < <(grep -rInE '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,})' \
         --exclude-dir=.git --exclude-dir=dist --exclude-dir=output . 2>/dev/null || true)
if (( secret_hits == 0 )); then
  pass "no secret patterns found"
fi

large=0
while IFS= read -r -d '' file; do
  size="$(osw_file_bytes "$file")"
  if (( size > 1048576 )); then
    fail "file larger than 1 MiB: ${file#./} (${size} bytes) — use a Release asset instead"
    large=$((large + 1))
  fi
done < <(find . -type f -not -path './.git/*' -not -path './dist/*' -not -path './build/output/*' -print0)
if (( large == 0 )); then
  pass "no tracked file exceeds 1 MiB"
fi

empty=0
while IFS= read -r -d '' file; do
  if [[ "$(osw_file_bytes "$file")" -eq 0 ]]; then
    fail "empty file: ${file#./}"
    empty=$((empty + 1))
  fi
done < <(find . -type f -not -path './.git/*' -not -path './dist/*' -not -path './build/output/*' -not -name '.gitkeep' -print0)
if (( empty == 0 )); then
  pass "no empty files"
fi

crlf=0
while IFS= read -r -d '' file; do
  if grep -qU $'\r' "$file" 2>/dev/null; then
    fail "CRLF line endings: ${file#./}"
    crlf=$((crlf + 1))
  fi
done < <(find . -type f \( -name '*.sh' -o -name '*.ini' -o -name '*.conf' -o -name '*.toml' \) -not -path './.git/*' -print0)
if (( crlf == 0 )); then
  pass "no CRLF line endings in shell/config files"
fi

# ---------------------------------------------------------------------------
section "docs"

broken_links=0
while IFS= read -r line; do
  file="${line%%:*}"
  rest="${line#*:}"
  target="$(printf '%s' "$rest" | sed -nE 's/.*\]\(([^)#]+)(#[^)]*)?\).*/\1/p')"
  [[ -z "$target" ]] && continue
  case "$target" in
    http://*|https://*|mailto:*|/*|\#*) continue ;;
  esac
  resolved="$(dirname -- "$file")/$target"
  if [[ ! -e "$resolved" ]]; then
    fail "broken relative link in $file: $target"
    broken_links=$((broken_links + 1))
  fi
done < <(grep -rInE '\]\([^)]+\)' --include='*.md' . 2>/dev/null | grep -v '^\./\.git' || true)
if (( broken_links == 0 )); then
  pass "all relative Markdown links resolve"
fi

# ---------------------------------------------------------------------------
printf '\n%sSummary%s\n' "$_osw_c_bold" "$_osw_c_reset"
printf '  passed:  %s%d%s\n' "$_osw_c_green" "$PASS" "$_osw_c_reset"
printf '  warnings:%s %d%s\n' "$_osw_c_yellow" "$WARN" "$_osw_c_reset"
printf '  failed:  %s%d%s\n' "$_osw_c_red" "$FAIL" "$_osw_c_reset"

if (( FAIL > 0 )); then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
printf '\n%sAll architectural checks passed.%s\n' "$_osw_c_green" "$_osw_c_reset"
