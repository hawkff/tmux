#!/usr/bin/env bash
# CPU usage for the tmux status bar.
# Apple Silicon: IOReport residency + SoC temperature via macmon
# (same data source as powermetrics/asitop, no sudo needed).
# Fallback: kernel tick deltas over a real sampling window (btop-style).
# LC_ALL=C: always available (en_US.UTF-8 may not be generated) and
# guarantees "." as decimal separator for awk/printf.
export LC_ALL=C
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

percent="" degrees=""

case $(uname -s) in
  Linux)
    # Delta of /proc/stat counters between consecutive status refreshes
    # (same math as btop: (dtotal - didle) / dtotal).
    state_file="${TMPDIR:-/tmp}/tmux-cpu-ticks-$(id -u)"
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + ${iowait:-0} + ${irq:-0} + ${softirq:-0} + ${steal:-0}))
    idle_all=$((idle + ${iowait:-0}))

    prev_total=0 prev_idle=0
    [ -r "$state_file" ] && read -r prev_total prev_idle < "$state_file"
    printf '%s %s\n' "$total" "$idle_all" > "$state_file"
    # first run or counter reset: fall back to usage since boot
    if [ "$prev_total" -ge "$total" ]; then
      prev_total=0 prev_idle=0
    fi

    percent=$(awk -v t="$total" -v i="$idle_all" -v pt="$prev_total" -v pi="$prev_idle" 'BEGIN {
      dt = t - pt; di = i - pi
      if (dt <= 0) dt = 1
      p = (dt - di) * 100 / dt
      if (p < 0) p = 0; if (p > 100) p = 100
      printf "%4.1f%%", p
    }')
    ;;

  Darwin)
    if [ "$(uname -m)" = "arm64" ] && command -v macmon >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      read -r pct temp < <(macmon pipe -s 1 -i 900 2>/dev/null |
        jq -r '"\(.cpu_usage_pct * 100) \(.temp.cpu_temp_avg)"' 2>/dev/null)
      if [ -n "$pct" ] && [ "$pct" != "null" ]; then
        percent=$(awk -v p="$pct" 'BEGIN { printf "%4.1f%%", p }')
        if [ -n "$temp" ] && [ "$temp" != "null" ]; then
          degrees=$(awk -v t="$temp" 'BEGIN { printf " %.0f°", t }')
        fi
      fi
    fi
    if [ -z "$percent" ]; then
      # Two samples 1s apart; the last line is real usage over that window
      # (top reads the same host_processor_info tick counters as btop).
      percent=$(top -F -R -l2 -n0 -s1 | awk '/^CPU usage/ { gsub(/%/, ""); u = $3; s = $5 } END { printf "%4.1f%%", u + s }')
    fi
    ;;

  *)
    percent="N/A"
    ;;
esac

echo "CPU $percent$degrees"
