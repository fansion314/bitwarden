#!/usr/bin/env bash
# Run as an ordinary user in Arch Linux with PKGBUILD dependencies installed.
set -euo pipefail
cd "$(dirname "$0")/../.."
root=$PWD
if (( EUID == 0 )); then
  echo 'Run this script as a non-root build user.' >&2
  exit 1
fi

mkdir -p dist .cache
for recipe in . bitwarden-electron; do
  (cd "$recipe" && makepkg --printsrcinfo) > dist/SRCINFO.generated
  diff -u "$recipe/.SRCINFO" dist/SRCINFO.generated
done
rm dist/SRCINFO.generated
export PKGDEST="$root/dist" SRCPKGDEST="$root/dist"
(
  cd bitwarden-electron
  makepkg --cleanbuild --force --noconfirm
  makepkg --source --force --noconfirm
)

source ./bitwarden-electron/PKGBUILD
version="${pkgver}-${pkgrel}"
[[ "$version" =~ ^[0-9][0-9A-Za-z.+_-]*$ ]]
printf 'v%s\n' "$version" > dist/tag.txt
package="$PKGDEST/${pkgname}-${version}-x86_64.pkg.tar.zst"
[[ -f "$package" && -f "$SRCPKGDEST/${pkgname}-${version}.src.tar.gz" ]]

# Generate and test the exact -bin recipe that will point at this release.
# Feed it the local build until publication makes the pinned URL available.
bin_dir=$(mktemp -d "$root/.cache/bin-recipe.XXXXXX")
node .github/scripts/render-bin.mjs PKGBUILD "$bin_dir" "$pkgver" "$pkgrel" "$package"
ln -s "$package" "$bin_dir/$(basename "$package")"
(
  cd "$bin_dir"
  makepkg --printsrcinfo > .SRCINFO
  makepkg --cleanbuild --force --noconfirm
  makepkg --source --force --noconfirm
)
mkdir -p dist/bin-recipe
cp "$bin_dir/PKGBUILD" "$bin_dir/.SRCINFO" dist/bin-recipe/

# Both package names must install byte-identical application content.
audit=$(mktemp -d "$root/.cache/payload-audit.XXXXXX")
mkdir "$audit/local" "$audit/bin"
bsdtar -xf "$package" -C "$audit/local" opt usr
bsdtar -xf "$PKGDEST/bitwarden-electron-bin-${version}-x86_64.pkg.tar.zst" -C "$audit/bin" opt usr
diff -qr --no-dereference "$audit/local" "$audit/bin"
bsdtar -tf "$package" > dist/package-files.txt
for entry in opt/Bitwarden/app.asar opt/Bitwarden/bitwarden \
             opt/Bitwarden/desktop_proxy opt/Bitwarden/libprocess_isolation.so usr/bin/bitwarden; do
  grep -qx "$entry" dist/package-files.txt
done
if grep -Eq '(^usr/lib/bitwarden/|chrome-sandbox|resources\.pak|icudtl\.dat|hibernate|patch-app)' dist/package-files.txt; then
  echo 'Unexpected bundled runtime or removed patch files in package.' >&2
  exit 1
fi
{
  printf 'Commit: %s\n' "$(git rev-parse HEAD)"
  printf 'Architecture: %s\n' "$(uname -m)"
  pacman -Q electron asar nodejs
  pacman -Q | grep -E '^electron[0-9]+ '
} > dist/build-info.txt
(
  cd dist
  sha256sum ./*.pkg.tar.zst ./*.src.tar.gz > SHA256SUMS
  sha256sum --check SHA256SUMS
)
cat > dist/release-notes.md <<EOF
Bitwarden Desktop ${pkgver} for Arch Linux x86_64 with system Electron.

- \`bitwarden-electron\`: extracts and repackages the official upstream release locally.
- \`bitwarden-electron-bin\`: downloads this repository's prebuilt \`bitwarden-electron\` package; no ASAR tooling is needed locally.

Install either package with \`sudo pacman -U <package>.pkg.tar.zst\`; the two variants conflict because they install the same files.
Application files are under \`/opt/Bitwarden\`. The \`electron\` dependency follows Arch's latest stable Electron.
Window closing, tray behavior, and SSH authorization remain upstream behavior.

Assets include both Arch packages, both makepkg source archives, checksums, and build metadata.
The -bin source archive contains the exact download URL and SHA-256 for this release.
Built from commit $(git rev-parse HEAD).
EOF
