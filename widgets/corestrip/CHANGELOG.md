# Changelog

## 1.0.0

First release.

- Panel gauges for processor, graphics, memory, network and disk activity,
  in four styles: plot and readout (default), rings, history bars, numbers.
- Readout adapts to panel height — two lines where they fit, a single
  `CPU 32% 51°` line where they do not — and reserves width for the widest
  value so the panel never shifts while numbers change.
- Hover tooltip summarising processor, graphics, memory, network and disk.
- Popup with per-core load, one card per GPU (usage, temperature, clock,
  power, video memory), memory breakdown, network and disk throughput,
  battery and the top processes by CPU or memory.
- All readings come from `ksystemstats`; sensors only the popup needs stay
  unsubscribed until it opens.
- Text size setting (50–150 %) that scales the readouts and the gauges
  together, within what the panel thickness allows.
