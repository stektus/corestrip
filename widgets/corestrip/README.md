# Corestrip

A Plasma 6 panel widget for CPU, GPU, memory, network and disk load.

Compact gauges sit in the panel — a history plot plus a live readout for each
metric, with temperatures alongside. Hovering shows a summary of the whole
machine; a click opens a detail popup with per-core load, one card per GPU,
memory breakdown, network and disk throughput, battery and the top processes.

All readings come from `ksystemstats`, the same daemon KDE's own System Monitor
uses — no polling scripts, no external tools. Sensors that only matter for the
popup (per-core clocks, processes, disk I/O) are subscribed exclusively while
the popup is open.

![Corestrip](docs/screenshot.png)

Four panel styles:

![Panel styles](docs/panel-styles.png)

## Requirements

- Plasma 6 (tested on 6.7)
- `ksystemstats`, `libksysguard` (part of a standard Plasma install)
- NVIDIA readings need `nvidia-smi`; Intel/AMD GPU readings come from the
  kernel's DRM interface

## Install

```sh
../../install.sh corestrip     # installs into ~/.local/share/plasma/plasmoids
```

Then add it: right-click the panel → *Add or Manage Widgets…* → **Corestrip**.

To update after changing the sources, run the install script again — it
upgrades an existing installation in place. Restart of `plasmashell` is not required, but
`systemctl --user restart plasma-plasmashell` picks up structural changes.

To remove:

```sh
../../uninstall.sh corestrip
```

### System-wide package (Arch/Manjaro)

```sh
makepkg -si           # builds and installs from PKGBUILD
```

`makepkg` produces `plasma6-applets-corestrip`, installed for every user on the
machine.

## Configuration

Right-click the widget → *Configure Corestrip…*

**Panel**
- Gauge style: *plot and readout* (default), rings, history bars, or plain numbers
- Which metrics appear in the panel: processor, graphics, memory, network, disk
- Temperatures next to the processor and graphics readouts
- Which GPU is shown when the machine has more than one
- Text size (50–150 %), which scales the readouts and the gauges together
- Update interval (1–30 s, default 2 s)

The readout adapts to the panel: tall panels get two lines (name and
temperature above, value below), short ones fall back to a single
`CPU 32% 51°` line. Raising the text size moves that line the same way — a
panel too short for two lines of the chosen size uses one. Widths are reserved for the widest possible value, so the
applet never resizes the panel while numbers change.

**Details** — which sections the popup shows: per-core load, graphics cards,
memory, network, storage, battery, top processes.

## What it reads

| Section    | Sensors |
|------------|---------|
| Processor  | `cpu/all/{usage,user,system}`, `cpu/cpuN/{usage,frequency}`, `cpu/cpu0/temperature` |
| Graphics   | `gpu/gpuN/{usage,temperature,power,coreFrequency,usedVram,totalVram}` |
| Memory     | `memory/physical/*`, `memory/swap/*` |
| Network    | `network/all/{download,upload,totalDownload,totalUpload}` |
| Storage    | `disk/all/{read,write,used,total,usedPercent}` |
| Battery    | `power/<id>/{chargePercentage,chargeRate,health}` |
| Processes  | `ProcessDataModel` (name, CPU usage, memory) |

## Packaging and publishing

Build a bundle for [store.kde.org](https://store.kde.org):

```sh
../../package.sh corestrip     # -> dist/corestrip-<version>.plasmoid
```

The bundle is a plain zip with `metadata.json` at its root, which is what both
`kpackagetool6 --install` and Plasma's *Get New Widgets* accept. Uploading it
to store.kde.org under *Plasma 6 → Plasma Widgets* makes it installable from
inside Plasma (*Add Widgets… → Get New Widgets…*) and visible in Discover.
`docs/panel.png`, `docs/popup.png` and `docs/panel-styles.png` are sized for a
store listing, and `docs/logo.png` is the 512×512 product logo.

Pushing a `v*` tag builds the bundle in CI and attaches it to the GitHub
release, so the file on the store and the file on the release page are the
same build.

For Arch/Manjaro users, [packaging/aur/](packaging/aur/) holds a ready
`PKGBUILD` and `.SRCINFO` pinned to the v1.0.0 release tarball — copy both into
a clone of the AUR repository and push. Once published, Manjaro's *Add/Remove
Software* installs it like any other package when AUR support is enabled.

## Layout

```
package/           the Plasma package (metadata.json + contents/)
  contents/ui/     QML: main.qml, Backend.qml, views and components
  contents/code/   shared JS helpers (formatting, palette)
  contents/config/ KConfigXT schema and config page list
packaging/aur/     PKGBUILD and .SRCINFO for the AUR
PKGBUILD           builds a system-wide package from this checkout
docs/              screenshots and the product logo
```

Build and install scripts live in the repository root and take the widget name.

## License

MIT — see [LICENSE](LICENSE).
