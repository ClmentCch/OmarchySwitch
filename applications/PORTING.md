# Guide de portage vers Arch Linux ARM64

Ce guide décrit la méthode, pas une liste de résultats. Aucun portage n'est
présenté comme réussi sans test sur console.

## 1. Qualifier l'application

| Question | Pourquoi |
|---|---|
| Quelle licence ? | Détermine si le paquet peut être distribué |
| Quelle source ? | Dépôt, tag, archive : indispensable pour un `PKGBUILD` reproductible |
| Langage ? | Un script shell se porte facilement ; un binaire Go/Rust statique aussi ; un binaire C++ lié à des bibliothèques Ubuntu non |
| Dépendances natives ? | Vérifier `aarch64` sur `archlinuxarm.org` |
| Accès matériel ? | Un outil qui parle à `/dev/input` ou à `nvidia-smi` doit être testé sur la console |

## 2. Choisir la voie

| Situation | Voie |
|---|---|
| Paquet Arch existant (même nom) | **Ne rien faire** : l'installer |
| Sources compilables | Écrire un `PKGBUILD` (`arch=('aarch64')`) |
| Scripts shell/outillage maison | `PKGBUILD` avec `arch=('any')` |
| Binaire Ubuntu uniquement | Recompiler depuis les sources, sinon `bloque` |
| Application propriétaire sans build ARM | `bloque` documenté, pas de contournement |

## 3. Squelette de `PKGBUILD`

```bash
pkgname=mon-outil
pkgver=1.2.3
pkgrel=1
pkgdesc="..."
arch=('aarch64')
url="https://exemple.org"
license=('GPL-3.0-only')
depends=('glibc')
makedepends=('meson' 'ninja')
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('<empreinte réelle>')

build() {
  cd "$pkgname-$pkgver"
  meson setup build --prefix=/usr
  meson compile -C build
}

package() {
  cd "$pkgname-$pkgver"
  DESTDIR="$pkgdir" meson install -C build
}
```

Règles :

- jamais `sha256sums=('SKIP')` dans un paquet destiné à être publié ;
- pas de `cd` hors de `$srcdir` ;
- pas de `sudo` dans un `PKGBUILD` ;
- licence du projet respectée et fichier de licence installé.

## 4. Tester

```bash
# dans un rootfs aarch64, jamais sur l'hôte x86_64
sudo ./scripts/build-rootfs.sh --output build/output/rootfs
sudo arch-chroot build/output/rootfs
# puis makepkg / pacman -U et exécution de l'outil
```

Puis, et seulement ensuite, tester sur la console. Un outil qui démarre dans un
chroot mais pas sur la console a un problème matériel (souvent : périphérique
absent, firmware manquant, ou attente d'un service systemd).

## 5. Documenter

Mettre à jour :

- `applications/switchroot/manifest.toml` (statut, licence, dépendances) ;
- `docs/05-status-matrix.md` (état réel) ;
- `THIRD-PARTY.md` si un nouveau composant upstream entre dans le projet.

## Cas connus à ne pas promettre

| Application | Difficulté |
|---|---|
| L4T-Megascript | Script Ubuntu : réécriture nécessaire, pas un simple empaquetage |
| `joycond` | Dépend d'un driver HID précis ; à tester avec les Joy-Con réels |
| Moonlight/Qt | Dépend du décodage vidéo (VIC/NVDEC) fourni par le BSP |
| Steam / Switchdeck | Hors périmètre, support ARM64 non validé ici |
| Émulateurs | Fonctionnent probablement, non testés ; dépendent de l'accélération GPU |
