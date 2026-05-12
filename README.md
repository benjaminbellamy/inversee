![](data/icons/hicolor/scalable/apps/fr.benjaminbellamy.Inversee.svg")

# Inversée

A Reverse Polish Notation (RPN) calculator for Linux,
built to look and feel like a native GNOME application.

> inversée \\ɛ̃.vɛʁ.se\\  
Participe passé féminin singulier de inverser.

The name *Inversée* plays on *notation polonaise inversée* — the French term
for RPN — and on the act of inverting an infix expression into postfix form.

## Features

- **Unbounded stack** (Forth/dc-style); every level is visible at once.
- **Arbitrary-precision arithmetic** via MPFR (128-bit internal precision,
  ~38 decimal digits).
- **Adwaita / GTK 4** interface, follows the system light/dark theme and accent.
- **Full RPN operation set**: `+`, `−`, `×`, `÷`, `mod`, `%`, `x^y`, `√`, `1/x`,
  `+/−`; stack ops `swap`, `drop`, `rot`, `dup`, `dup2`, `clear`.
- **Unbounded undo** (capped at 1000 entries per session).
- **Locale-aware display** (`,` or `.` decimal separator) and
  **locale-tolerant clipboard paste** (thin / non-breaking thousands
  separators, scientific notation, both decimal separators).
- **Clipboard**: copy X, copy the whole stack, paste any whitespace-separated
  list of values.
- **Translations**: English (source), French, German, Italian, Spanish,
  Polish — switchable from the in-app menu.
- **Fully offline** — no network access, no telemetry.

## Status

Pre-release. Core engine and UI work end-to-end; file-based session
persistence (auto-save / auto-restore of stack and history on launch) is
the remaining UI wiring.

## Keyboard shortcuts

| Key                | Action                                  |
|--------------------|-----------------------------------------|
| `0`–`9`            | Digit entry                             |
| `.` or `,`         | Decimal separator (locale-tolerant)     |
| `Enter`            | Push entry / duplicate X                |
| `Backspace`        | Delete last char / drop X               |
| `+` `−` `×` `÷`    | Arithmetic                              |
| `%` / `^`          | Percent of / power (`x^y`)              |
| `r` / `i` / `n`    | Square root / inverse `1/x` / negate    |
| `m` / `s` / `d` / `t` | mod / swap / drop / rot              |
| `Escape`           | Clear stack                             |
| `Ctrl+Z`           | Undo                                    |
| `Ctrl+C` / `Ctrl+V`| Copy X / paste                          |

The same shortcuts are reachable from the on-screen keypad and the
hamburger menu's **Keyboard Shortcuts** dialog.

## Build

### Local (host)

Requires `meson`, `ninja`, `valac`, `gettext`, plus the development headers
for GLib, GTK 4, libadwaita, MPFR, and json-glib.

```sh
meson setup build
meson compile -C build
meson test -C build --print-errorlogs
./build/src/inversee
```

The binary can be run uninstalled directly from the build tree —
translations, the GSettings schema, and the application icon are all
discovered from the build directory when launched that way.

### Flatpak

The Flatpak manifest is the canonical build reference.

```sh
flatpak-builder --user --install --force-clean \
    build-flatpak build-aux/fr.benjaminbellamy.Inversee.yml
flatpak run fr.benjaminbellamy.Inversee
```

## Tests

The numeric and stack engine is a pure-logic static library
(`libinversee-core`) with no GTK dependency. It ships with GLib-based
test binaries for every module:

```sh
meson test -C build --print-errorlogs
```

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

## Author

Benjamin Bellamy &lt;benjamin@castopod.org&gt;
