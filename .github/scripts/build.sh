#!/usr/bin/env bash
# Run as an ordinary user in Arch Linux with PKGBUILD dependencies installed.
set -euo pipefail
cd "$(dirname "$0")/../.."
if (( EUID == 0 )); then
  echo 'Run this script as a non-root build user.' >&2
  exit 1
fi

mkdir -p dist
makepkg --printsrcinfo > dist/SRCINFO.generated
diff -u .SRCINFO dist/SRCINFO.generated
rm dist/SRCINFO.generated
export PKGDEST="$PWD/dist" SRCPKGDEST="$PWD/dist"
makepkg --cleanbuild --force --noconfirm
makepkg --source --force --noconfirm

# This is our reviewed PKGBUILD, not metadata from a downloaded package.
source ./PKGBUILD
version="${pkgver}-${pkgrel}"
[[ "$version" =~ ^[0-9][0-9A-Za-z.+_-]*$ ]]
printf 'v%s\n' "$version" > dist/tag.txt

packages=("dist/${pkgname}-${version}-"*.pkg.tar.zst)
sources=("dist/${pkgname}-${version}.src.tar.gz")
[[ ${#packages[@]} == 1 && -f "${packages[0]}" && -f "${sources[0]}" ]]
bsdtar -tf "${packages[0]}" > dist/package-files.txt
grep -qx 'opt/Bitwarden/app.asar' dist/package-files.txt
grep -qx 'opt/Bitwarden/bitwarden' dist/package-files.txt
grep -qx 'opt/Bitwarden/desktop_proxy' dist/package-files.txt
grep -qx 'opt/Bitwarden/libprocess_isolation.so' dist/package-files.txt
grep -qx 'usr/bin/bitwarden' dist/package-files.txt
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
Repackages the official Bitwarden Desktop ${pkgver} Linux x86_64 release using Arch Linux's system Electron.

Install the package with \`sudo pacman -U ${pkgname}-${version}-x86_64.pkg.tar.zst\`.
The \`electron\` dependency follows Arch's latest stable Electron package.
Application files are installed under \`/opt/Bitwarden\`; commands in \`/usr/bin\` are symlinks.
Window closing, tray behavior, and SSH authorization remain upstream behavior.

Assets include the Arch package, makepkg source archive, SHA-256 checksums, package file list, and build environment versions.
Built from commit $(git rev-parse HEAD).
EOF
