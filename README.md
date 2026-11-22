# vedma's MPV remote

A drawn picture remote for the fish **radio suite** (package: vedma's MPV remote; command: `radio-remote`), built for a phone
terminal. It renders a remote control — LCD now-playing screen, volume
bar, labelled buttons — in box-drawing characters (no emoji, no
images), and drives a radio playing on another machine over ssh.

```
╭────────────────────────────────────────────╮
│  VEDMA'S MPV REMOTE                  IwIn  │
├────────────────────────────────────────────┤
│ ╔════════════════════════════════════════╗ │
│ ║ 90s90s Rock                            ║ │
│ ║ ▶ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░ 75            ║ │
│ ╚════════════════════════════════════════╝ │
│ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐  │
│ │ STOP  │ │ PAUSE │ │ MUTE  │ │ NOW   │  │
│ │ x     │ │ space │ │ m     │ │ n     │  │
│ └───────┘ └───────┘ └───────┘ └───────┘  │
│ ┌───────┐ ┌───────┐ ┌─────────────────┐  │
│ │ VOL - │ │ VOL + │ │ STATIONS        │  │
│ │ -     │ │ +     │ │ s               │  │
│ └───────┘ └───────┘ └─────────────────┘  │
│  q quit — music keeps playing            │
╰────────────────────────────────────────────╯
```

The drawing is a skin. Underneath it is the suite's own protocol —
`__radio_ctl_once` for control, `__radio_stations` for the station
list, `radio <key>` to switch — one ssh call per keypress, nothing
faked. The face redraws itself as state changes and adapts to narrow
terminals (full grid → compact grid → minimal legend).

## Requirements

- bash and ssh on the machine you run the remote from (Termux works
  great)
- on each target machine: the fish radio suite (`radio`, `radio-ctl`
  and friends) and key-based ssh access from the remote

## Install

```sh
git clone <this repo> && cd radio-remote
./install.sh
```

The installer is idempotent. On Termux it installs into `$PREFIX/bin`;
on plain Linux into `~/.local/bin`. It also drops a fish wrapper into
`~/.config/fish/functions/` when fish is around, and seeds your config
from the example — once; your edits are never overwritten.

## Configure

Machines live in `~/.config/radio-remote/machines.conf`, one per line,
tab-separated:

```
# name <TAB> ssh destination <TAB> identity file or -
iwantitnow	verucasaltywitch@100.74.247.90	-
bluefin	velrooins@100.79.74.93	-
```

The shipped example is the author's fleet, as a worked example — point
it at your own machines. The first line is the default target.
Override the path with `RADIO_REMOTE_CONFIG`.

## Use

```sh
radio-remote            # remote for the default machine
radio-remote bluefin    # remote for a named machine
radio-remote --render-once bluefin   # print one frame and exit
```

## Keys

| key | action |
| --- | --- |
| `space` / `p` | pause / resume |
| `+` / `-` | volume up / down |
| `m` | mute |
| `s` | station list (numbered, from the target) |
| `x` | stop the radio on the target |
| `n` | refresh now-playing |
| `q` | quit the remote — the music keeps playing |

## Development

Spec first (`SPEC.md`), tests before code:

```sh
bash tests/run_tests.sh
```

`tests/RED.log` is the recorded failing run against the pre-implementation
stub; the suite is green now. Rendering and `--render-once` need no
network; `RADIO_REMOTE_STATE="playing|Some Station|60|0"` renders a
fixture frame offline.
