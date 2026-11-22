#!/usr/bin/env bash
# radio-remote test suite — plain bash, no framework.
# Run: bash tests/run_tests.sh   (exit 0 = all green)
# All assertions evaluate in THIS shell (the binary is sourced as a
# library); a child bash would not see its functions.
set -u
export LC_ALL=C.UTF-8
cd "$(dirname "$0")/.."
BIN=bin/radio-remote
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "ok   - $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL - $1"; }
check(){ local name="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi
}
contains()    { grep -qF "$2" <<< "$1"; }
not_contains(){ ! grep -qF "$2" <<< "$1"; }
starts_with() { case "$1" in "$2"*) return 0 ;; *) return 1 ;; esac; }
ends_with()   { case "$1" in *"$2") return 0 ;; *) return 1 ;; esac; }
maxlen() {
    local m=0 l n
    while IFS= read -r l; do
        n=$(printf %s "$l" | wc -m)
        [ "$n" -gt "$m" ] && m=$n
    done <<< "$1"
    echo "$m"
}
uniform() {
    local want="" l n
    while IFS= read -r l; do
        n=$(printf %s "$l" | wc -m)
        [ -z "$want" ] && want=$n
        [ "$n" = "$want" ] || return 1
    done <<< "$1"
    return 0
}
filled() { printf %s "$1" | tr -cd '▓' | wc -m; }
is_eq()  { [ "$1" = "$2" ]; }
is_le()  { [ "$1" -le "$2" ]; }

export RADIO_REMOTE_LIB=1
# shellcheck disable=SC1091
source "$BIN"

# ---------- R1/R2: full frame at default width ----------
F=$(render_frame 46 IwIn playing "90s90s Rock" 75 0)
FIRST=$(head -n1 <<< "$F"); LAST=$(tail -n1 <<< "$F")
check "R1 frame opens with ╭"   starts_with "$FIRST" "╭"
check "R1 frame closes with ╯"  ends_with "$LAST" "╯"
check "R1 uniform line width"   uniform "$F"
check "R2 shows machine"        contains "$F" "IwIn"
check "R2 shows title"          contains "$F" "90s90s Rock"
check "R2 shows play glyph"     contains "$F" "▶"
check "R2 shows volume number"  contains "$F" "75"

# ---------- R3: volume bar math ----------
N=$(filled "$F");  check "R3 75% -> 15 filled"  is_eq "$N" 15
F0=$(render_frame 46 IwIn playing "X" 0 0)
N=$(filled "$F0"); check "R3 0% -> 0 filled"    is_eq "$N" 0
F100=$(render_frame 46 IwIn playing "X" 100 0)
N=$(filled "$F100"); check "R3 100% -> 20 filled" is_eq "$N" 20

# ---------- R4: muted ----------
FM=$(render_frame 46 IwIn playing "90s90s Rock" 75 1)
check "R4 muted shows MUTED" contains "$FM" "MUTED"
N=$(filled "$FM"); check "R4 muted bar empty" is_eq "$N" 0

# ---------- R5: standby ----------
FS=$(render_frame 46 IwIn standby "" 0 0)
check "R5 standby label"     contains "$FS" "STANDBY"
check "R5 standby hint"      contains "$FS" "press s"
check "R5 no fake title"     not_contains "$FS" "90s90s"

# ---------- R6: truncation ----------
FL=$(render_frame 46 IwIn playing "A Very Long Station Name That Goes On Forever And Ever" 50 0)
check "R6 truncates with …"  contains "$FL" "…"
M=$(maxlen "$FL"); check "R6 stays in width" is_le "$M" 46

# ---------- R7: width tiers ----------
for W in 46 38 30; do
    FW=$(render_frame $W IwIn playing "90s90s Rock" 75 0)
    M=$(maxlen "$FW"); check "R7 width $W respected" is_le "$M" "$W"
done
F30=$(render_frame 30 IwIn playing "90s90s Rock" 75 0)
check "R7 full grid has STATIONS at 46" contains "$F" "STATIONS"
check "R7 minimal at 30 has legend q"   contains "$F30" "q"

# ---------- R8: key labels ----------
for K in "x" "space" "m" "n" "+" "-" "s" "q"; do
    check "R8 key label '$K' drawn" contains "$F" "$K"
done

# ---------- C1-C3: config ----------
TMPC=$(mktemp)
printf '# comment\n\nalpha\tuser@1.2.3.4\t-\nbeta\tuser@5.6.7.8\t~/.ssh/id_x\n' > "$TMPC"
export RADIO_REMOTE_CONFIG="$TMPC"
# config is read at source time in v1 of the binary; re-source per file:
CONFIG_FILE="$TMPC"
D=$(machine_dest alpha);  check "C1 known machine dest" is_eq "$D" "user@1.2.3.4"
unknown_fails() { ! machine_dest nope >/dev/null 2>&1; }
check "C1 unknown fails" unknown_fails
DF=$(machine_default);    check "C3 first machine is default" is_eq "$DF" "alpha"
unset RADIO_REMOTE_CONFIG
CONFIG_FILE="/nonexistent/machines.conf"
DF=$(machine_default);    check "C2 fallback default exists" bash -c "[ -n \"$DF\" ]"
rm -f "$TMPC"

# ---------- P4: switch call detaches remote stdio (issue #1) ----------
check "P4 switch redirects remote stdio" grep -qF 'radio ${keys[$((choice-1))]} >/dev/null 2>&1' "$BIN"

# ---------- K2: render-once needs no ssh ----------
STUB=$(mktemp -d); printf '#!/bin/sh\nexit 127\n' > "$STUB/ssh"; chmod +x "$STUB/ssh"
OUT=$(PATH="$STUB:$PATH" RADIO_REMOTE_LIB= RADIO_REMOTE_STATE="playing|Demo Station|60|0" "$BIN" --render-once IwIn 2>/dev/null)
check "K2 render-once offline" contains "$OUT" "Demo Station"
rm -rf "$STUB"

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
