# mascot.sh — Fork-only Claude Code mascot for the status line.
#
# This file does not exist in the upstream repo (daniel3303/ClaudeCodeStatusLine),
# so it never produces merge conflicts. It is sourced by statusline.sh and relies on
# variables already defined there at print time:
#   - color vars : $green $yellow $orange $red $cyan $reset
#   - helper     : usage_color <pct>
#   - state      : $out $out2 $update_line $pct_used $five_hour_pct $seven_day_pct
#
# 色   = token/5h/7d の最大使用率 (usage_color: 緑→黄→橙→赤)
# ポーズ = イベント (更新あり=happy, ≥90%=panic, ≥70%=busy, それ以外=calm)
#
# Tune freely: each art line below is padded to a fixed display width (W=9 columns).
# Block-drawing glyphs are width-1 in most terminals; keep every line exactly 9 cols.

# Set MA1/MA2/MA3 (3 art rows) for the given state.
# bash 3.2 (macOS default) compatible: no associative arrays.
mascot_frame() {
    case "$1" in
        happy)            # update available — arms raised
            MA1=" ╲▛███▜╱ "
            MA2="▝▜█████▛▘"
            MA3="  ▘▘ ▝▝  " ;;
        panic)            # >=90% — alarmed, legs spread
            MA1=" ▐▛███▜  "
            MA2="▝▜█████▛▘"
            MA3=" ▘ ▘ ▝ ▝ " ;;
        busy)             # >=70% — shifting feet
            MA1=" ▐▛███▜  "
            MA2="▝▜█████▛▘"
            MA3="  ▝▘ ▘▝  " ;;
        *)                # calm (default)
            MA1=" ▐▛███▜  "
            MA2="▝▜█████▛▘"
            MA3="  ▘▘ ▝▝  " ;;
    esac
}

# Echo the largest integer percentage among the given args (missing/garbage -> 0).
_mascot_max_pct() {
    local max=0 v
    for v in "$@"; do
        v=$(printf '%.0f' "${v:-0}" 2>/dev/null) || v=0
        [ -z "$v" ] && v=0
        if [ "$v" -gt "$max" ] 2>/dev/null; then max=$v; fi
    done
    printf '%d' "$max"
}

# Echo a value coerced to a clamped integer percentage 0..100 (garbage -> 0).
_mascot_int() {
    local v
    v=$(printf '%.0f' "${1:-0}" 2>/dev/null) || v=0
    [ -z "$v" ] && v=0
    [ "$v" -lt 0 ] 2>/dev/null && v=0
    [ "$v" -gt 100 ] 2>/dev/null && v=100
    printf '%d' "$v"
}

# Echo a gauge bar: ━ (filled) ╌ (empty), width cells, line style (no half-cell).
# Note: macOS bash 3.2 corrupts multibyte concatenation in a UTF-8 locale, so the
# bar string is assembled in byte mode (local LC_ALL=C, restored on function return).
_mascot_bar() {
    local LC_ALL=C pct=$1 width=$2 full empty s="" i=0
    full=$(( (pct * width + 50) / 100 ))
    empty=$(( width - full ))
    [ "$empty" -lt 0 ] && empty=0
    while [ "$i" -lt "$full"  ]; do s="$s━"; i=$((i + 1)); done
    i=0
    while [ "$i" -lt "$empty" ]; do s="$s╌"; i=$((i + 1)); done
    printf '%s' "$s"
}

# Echo ctx / 5h / 7d gauges sized to match the visible width of each corresponding
# segment in out2, so bars align column-for-column with the numbers on the row above.
# Segments: "{used}/{total} ({pct}%)" | "5h {pct}% @{time}" | "7d {pct}% @{time}"
# Bar frame: ctx[{bar}] matching the token segment width; 5h[...] / 7d[...] likewise.
mascot_gauges() {
    local p_ctx p_5h p_7d c_ctx c_5h c_7d
    local tok_plain fh_plain sd_plain bw_ctx bw_5h bw_7d
    p_ctx=$(_mascot_int "$pct_used")
    p_5h=$(_mascot_int "$five_hour_pct")
    p_7d=$(_mascot_int "$seven_day_pct")
    c_ctx=$(usage_color "$p_ctx")
    c_5h=$(usage_color "$p_5h")
    c_7d=$(usage_color "$p_7d")

    tok_plain="${used_tokens}/${total_tokens} (${pct_used}%)"
    bw_ctx=$(( ${#tok_plain} - 5 ))          # 4="ctx[" + 1="]"
    [ "$bw_ctx" -lt 2 ] && bw_ctx=2

    fh_plain="5h ${five_hour_pct}%"
    [ -n "$five_hour_reset" ] && fh_plain="${fh_plain} @${five_hour_reset}"
    bw_5h=$(( ${#fh_plain} - 4 ))            # 3="5h[" + 1="]"
    [ "$bw_5h" -lt 2 ] && bw_5h=2

    sd_plain="7d ${seven_day_pct}%"
    [ -n "$seven_day_reset" ] && sd_plain="${sd_plain} @${seven_day_reset}"
    bw_7d=$(( ${#sd_plain} - 4 ))            # 3="7d[" + 1="]"
    [ "$bw_7d" -lt 2 ] && bw_7d=2

    printf '%s' \
"${dim}ctx[${reset}${c_ctx}$(_mascot_bar "$p_ctx" "$bw_ctx")${reset}${dim}]${reset} \
${dim}|${reset} \
${dim}5h[${reset}${c_5h}$(_mascot_bar "$p_5h" "$bw_5h")${reset}${dim}]${reset} \
${dim}|${reset} \
${dim}7d[${reset}${c_7d}$(_mascot_bar "$p_7d" "$bw_7d")${reset}${dim}]${reset}"
}

# Compose and print the final multi-line output with the mascot on the left.
# Row layout: 1 = model/dir/effort (out), 2 = usage numbers (out2), 3 = ctx/5h/7d gauges.
# Bars sit directly below the numbers they visualize. $update_line keeps its leading
# "\n", so an update notice appears as row 4 only when one is available.
render_with_mascot() {
    local m col state gauges
    m=$(_mascot_max_pct "$pct_used" "$five_hour_pct" "$seven_day_pct")
    col=$(usage_color "$m")

    # Pose event priority: update > panic > busy > calm
    if [ -n "$update_line" ]; then state=happy
    elif [ "$m" -ge 90 ]; then state=panic
    elif [ "$m" -ge 70 ]; then state=busy
    else state=calm
    fi
    mascot_frame "$state"

    gauges=$(mascot_gauges)

    printf "%b\n%b\n%b" \
        "${col}${MA1}${reset}  ${out}" \
        "${col}${MA2}${reset}  ${out2}" \
        "${col}${MA3}${reset}  ${gauges}${update_line}"
}
