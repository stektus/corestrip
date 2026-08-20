# Tunestrip

A Plasma 6 panel widget for whatever is playing — album art, an animated
equalizer and the title in the panel, full controls one click away.

![Tunestrip](docs/screenshot.png)

## What it shows

**In the panel** — album art, the equalizer, the title block and the transport
buttons, each optional and in whatever order you put them. A hairline under the
widget tracks the position. Long titles scroll; the text size scales the whole
strip at once.

**In the popup** — the cover at a readable size, title, artist and album, a
seek bar, shuffle, previous, play, next and repeat, the volume, and a list of
players when more than one is running.

**Hovering** shows the cover, the track and how far into it you are.

The scroll wheel over the widget changes the volume and a middle click plays or
pauses — both can be switched off.

## Where the data comes from

MPRIS2 on the session bus, the same interface Plasma's own media controls read.
Anything that announces itself there is understood:

- browsers, through `plasma-browser-integration` (YouTube, Spotify web, and the
  rest),
- desktop players — VLC, Elisa, Amarok, Audacious, Clementine, Strawberry,
- `mpv` with an MPRIS plugin, `mpd` through `mpDris2`, Spotify's own client.

Nothing is polled except the position, and only while something plays and only
while a view actually shows it.

## About the equalizer

It is an indicator, not a spectrum analyser. A Plasma applet cannot read the
audio stream — that would take a capture client and a native plugin — so the
motion is generated from the track rather than measured from it. It is
deterministic, so it never jumps on a repaint, and it settles to a flat line
when the music stops.

Five styles: bars, blocks, wave, dots and pulse. The colour can follow the
album art, the accent colour or the text colour.

## Settings

- **Panel** — what to show and in which order, text size, title width, the
  second line with the artist, scrolling titles, the progress line, collapsing
  when nothing plays, wheel and middle-click behaviour.
- **Equalizer** — style, columns, speed, colour, whether it keeps moving while
  paused. The page shows a live preview.
- **Popup** — album art, equalizer, seek bar, volume, player list.

## Install

From this checkout:

```sh
./install.sh tunestrip     # from the repository root
```

Then right-click the panel → *Add or Manage Widgets…* → **Tunestrip**.

As a system package (Arch/Manjaro): `makepkg -si` in this directory.

## Requirements

Plasma 6 and `plasma-workspace` — the MPRIS reader ships with it. For browser
playback, install `plasma-browser-integration` and its extension.

## Licence

MIT — see [LICENSE](../../LICENSE).
