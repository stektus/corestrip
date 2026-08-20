# Daystrip

A Plasma 6 panel widget for the clock, the date and the weather, with a
calendar, a seven-day forecast and your agenda one click away.

![Daystrip](docs/screenshot.png)

## What it shows

**In the panel** — any combination of time, date, weekday and current weather,
in whatever order you put them. Everything scales with the panel height, and a
text size setting (50–150 %) moves the clock, the date and the weather together
so the strip keeps its proportions. Time and date stack into two lines when
they sit next to each other and the panel is tall enough; otherwise everything
stays on one line. Widths are reserved for
the longest reading, so the panel never shifts as the clock ticks.

**In the popup**

- Current conditions: temperature, what it feels like, humidity, wind, sunrise
  and sunset.
- Seven-day forecast, each day drawn as a bar spanning its range against the
  week's range, with precipitation chance where it matters.
- Month view with a dot per calendar on days that have events; click any day to
  see it.
- Agenda for the selected day, or the next few events when today is clear.

Weather symbols are drawn by the widget rather than taken from the icon theme,
so they look the same everywhere.

## Where the data comes from

- **Weather**: [Open-Meteo](https://open-meteo.com) — no account, no API key.
  Only the coordinates you pick are sent.
- **Calendars**: any iCalendar (`.ics`) address. In Google Calendar that is
  *Settings → Settings for my calendars → Integrate calendar → Secret address
  in iCal format*; Nextcloud, Outlook and CalDAV servers publish the same kind
  of link.

Those addresses are secrets — anyone holding one can read that calendar. They
are stored in the widget's own configuration file and are only ever sent to the
server they point at.

Known limits: Google refreshes a secret iCal address on its own schedule, so a
brand-new event can take a while to appear. A `TZID` in a feed is read as local
time, which is correct as long as the calendar and the machine share a time
zone. Recurrence rules cover the common cases (`FREQ`, `INTERVAL`, `COUNT`,
`UNTIL`, weekly `BYDAY`, `EXDATE`) — not `BYSETPOS` or `BYWEEKNO`.

## Requirements

- Plasma 6 (tested on 6.7)
- A network connection for weather and calendars; the clock works without one

## Install

```sh
../../install.sh daystrip     # installs into ~/.local/share/plasma/plasmoids
```

Then add it: right-click the panel → *Add or Manage Widgets…* → **Daystrip**.

To remove: `../../uninstall.sh daystrip`.

### System-wide package (Arch/Manjaro)

```sh
makepkg -si
```

## Configuration

Right-click the widget → *Configure Daystrip…*

- **Panel** — what appears in the panel, its order and text size, 12/24-hour
  clock, seconds, date format, first day of the week, and which popup sections
  to show.
- **Weather** — start typing a city and pick it from the results, choose units,
  set the refresh interval.
- **Calendars** — add iCal addresses, name them, set the refresh interval.

## Layout

```
package/           the Plasma package (metadata.json + contents/)
  contents/ui/     QML: main.qml, Backend.qml, views and components
  contents/code/   util.js (formatting) and ical.js (the iCalendar reader)
  contents/config/ KConfigXT schema and config page list
packaging/aur/     PKGBUILD for the AUR
PKGBUILD           builds a system-wide package from this checkout
docs/              screenshots and the product logo
```

## License

MIT — see [../../LICENSE](../../LICENSE).
