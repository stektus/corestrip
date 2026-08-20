# Maintainer: stektus <stektus@users.noreply.github.com>
pkgname=plasma6-applets-corestrip
pkgver=1.0.0
pkgrel=1
pkgdesc="Plasma 6 panel widget for CPU, GPU, memory and network load"
arch=('any')
url="https://github.com/stektus/corestrip"
license=('MIT')
depends=('plasma-workspace' 'ksystemstats' 'libksysguard')
optdepends=('nvidia-utils: NVIDIA GPU readings')
source=()

package() {
    local appletdir="$pkgdir/usr/share/plasma/plasmoids/io.github.stektus.corestrip"
    install -dm755 "$appletdir"
    cp -r "$startdir/package/." "$appletdir/"
    find "$appletdir" -type f -exec chmod 644 {} +
    find "$appletdir" -type d -exec chmod 755 {} +

    install -Dm644 "$startdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
