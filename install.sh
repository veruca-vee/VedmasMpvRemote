#!/usr/bin/env bash
# radio-remote installer — Termux and plain Linux. Idempotent. 🖤🩷
#   ./install.sh
# Installs:
#   bin/radio-remote        -> $PREFIX/bin        (Termux)
#                              or ~/.local/bin    (Linux)
#   fish/radio-remote.fish  -> ~/.config/fish/functions/ (when fish exists)
#   config/machines.example.conf -> ~/.config/radio-remote/machines.conf
#                              (only when no config exists yet)
set -eu
cd "$(dirname "$0")"

if [ -n "${PREFIX:-}" ]; then
    BIN_DIR="$PREFIX/bin"
else
    BIN_DIR="$HOME/.local/bin"
fi
mkdir -p "$BIN_DIR"
install -m 0755 bin/radio-remote "$BIN_DIR/radio-remote"
echo "installed: $BIN_DIR/radio-remote"

FISH_DIR="$HOME/.config/fish/functions"
if command -v fish >/dev/null 2>&1 || [ -d "$FISH_DIR" ]; then
    mkdir -p "$FISH_DIR"
    install -m 0644 fish/radio-remote.fish "$FISH_DIR/radio-remote.fish"
    echo "installed: $FISH_DIR/radio-remote.fish"
fi

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/radio-remote"
mkdir -p "$CONF_DIR"
if [ -e "$CONF_DIR/machines.conf" ]; then
    echo "kept existing config: $CONF_DIR/machines.conf"
else
    install -m 0644 config/machines.example.conf "$CONF_DIR/machines.conf"
    echo "installed: $CONF_DIR/machines.conf (edit it — it ships with the author's fleet as the example)"
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "note: $BIN_DIR is not on your PATH — add it, or call $BIN_DIR/radio-remote" ;;
esac
echo "done. usage: radio-remote [machine]   (see README.md)"
