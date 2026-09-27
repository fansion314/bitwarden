# Download this repository's preprocessed system-Electron application archive.
# No upstream DEB extraction, ASAR processing, or application build is performed.
pkgname=bitwarden-electron-bin
pkgver=2026.9.0
pkgrel=4
pkgdesc='Bitwarden using system Electron (prebuilt application)'
arch=('x86_64')
url='https://github.com/fansion314/bitwarden'
license=('GPL-3.0-only')
depends=('electron' 'bash' 'glibc' 'libgcc' 'hicolor-icon-theme'
         'libnotify' 'org.freedesktop.secrets' 'libxtst' 'libxss' 'libnss_nis')
provides=("bitwarden=$pkgver" "bitwarden-electron=$pkgver")
conflicts=('bitwarden' 'bitwarden-bin' 'bitwarden-electron')
options=('!strip' '!debug')
# Independently pin the published input: pkgrel can change without rebuilding it.
_release='2026.9.0-3'
_archive='bitwarden-electron-2026.9.0-3-x86_64.pkg.tar.zst'
source=("https://github.com/fansion314/bitwarden/releases/download/v${_release}/${_archive}")
noextract=("$_archive")
sha256sums=('43a7bb227e49d725045e525f04fae256cfe2fe00c701df28915e3f00b8e59687')

package() {
  # Package the prepared application files; makepkg supplies pacman metadata.
  bsdtar -xf "$srcdir/$_archive" -C "$pkgdir" opt usr
}
