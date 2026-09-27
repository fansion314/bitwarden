# Download this repository's prebuilt system-Electron package.
# No upstream DEB extraction, ASAR processing, or application build is performed.
pkgname=bitwarden-electron-bin
pkgver=2026.9.0
pkgrel=3
pkgdesc='Bitwarden using system Electron (prebuilt package)'
arch=('x86_64')
url='https://github.com/fansion314/bitwarden'
license=('GPL-3.0-only')
depends=('electron' 'bash' 'glibc' 'libgcc' 'hicolor-icon-theme'
         'libnotify' 'org.freedesktop.secrets' 'libxtst' 'libxss' 'libnss_nis')
provides=("bitwarden=$pkgver" "bitwarden-electron=$pkgver")
conflicts=('bitwarden' 'bitwarden-bin' 'bitwarden-electron')
options=('!strip' '!debug')
# Independently pin the published input: pkgrel can change without rebuilding it.
_release='2026.9.0-2'
_archive='bitwarden-electron-bin-2026.9.0-2-x86_64.pkg.tar.zst'
source=("https://github.com/fansion314/bitwarden/releases/download/v${_release}/${_archive}")
noextract=("$_archive")
sha256sums=('41f33f578fad129b22b020d2f9fe026c13799ff661cfa5f4c580354b562e073c')

package() {
  # Copy only installed payload, excluding the input package's pacman metadata.
  bsdtar -xf "$srcdir/$_archive" -C "$pkgdir" opt usr
}
