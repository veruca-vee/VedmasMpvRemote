# vedma's MPV remote — spec

A phone-first terminal remote for the fish `radio` suite. It draws a
picture of a remote control (box-drawing characters only, no emoji)
and drives a radio playing on another machine over ssh, using the
suite's own one-shot control (`__radio_ctl_once`) and station list
(`__radio_stations`). The drawing is a skin; the protocol and key map
are exactly radio-ctl's.

## Checkable statements

### Rendering (`render_frame`, pure: state in, frame out)
- R1. The frame is a box: first line starts with `╭`, last line ends
  with `╯`, and every line has the same character width.
- R2. At the default width (46) the LCD shows the machine name, the
  station/title, the play state (▶ playing, ❚❚ paused), and the
  volume as a bar plus a number.
- R3. Volume bar: 20 cells; filled cells = round(volume/100 × 20)
  (75 → 15 filled, 0 → 0, 100 → 20).
- R4. Muted state renders the word `MUTED` in the LCD and an empty bar.
- R5. Nothing-playing state renders a standby LCD containing
  `STANDBY` and `press s` — never a fake station name.
- R6. Long titles are truncated with `…` so the frame never exceeds
  the requested width.
- R7. Width tiers: width ≥ 42 → full button grid; 33–41 → compact
  grid; < 33 → minimal (LCD + one-line key legend). At widths 46, 38
  and 30 no line exceeds the requested width.
- R8. The button grid labels every protocol key on its button:
  `x`, `space`, `m`, `n`, `+`, `-`, `s`, and the footer labels `q`.

### Config (`machines.conf`, tab-separated: name, ssh-dest, identity)
- C1. `machine_dest <name>` prints the ssh destination for a listed
  machine and fails (non-zero, no output on stdout) for unknown names.
- C2. With no argument and no config, the built-in default is the
  example fleet (iwantitnow first).
- C3. Lines starting with `#` and blank lines are ignored.

### Protocol (unchanged from radio-ui.sh)
- P1. Keys: space/p pause-toggle, +/- volume, m mute, s station list,
  x stop, n refresh, q quit. Quit never stops the music.
- P2. Every action is one ssh call to the target running
  `fish -ic '__radio_ctl_once <action>'`; station switches run
  `fish -ic 'radio <key>'`; the station list comes from
  `fish -ic '__radio_stations'`.
- P3. ssh is always invoked with `-n` (never eats the key stream) and
  a connect timeout.

### Packaging
- K1. `install.sh` works with `PREFIX` set (Termux) and without
  (plain Linux → `~/.local/bin`), is idempotent, installs the
  executable, the fish wrapper (when a fish functions dir exists or
  fish is present), and a config from the example only when none
  exists.
- K2. The executable runs with `bash` only (plus `ssh` at runtime);
  rendering and `--render-once` need no ssh and no network.
- K3. Nothing Vee-specific is hard-coded in the executable: machines
  come from the config file; the shipped example config is editable
  documentation, not the only option.

## Out of scope
- Replacing radio-ui.sh anywhere. radio-remote builds alongside it.
- Any playback feature the radio suite does not already have.
