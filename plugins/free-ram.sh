#!/usr/bin/env bash
# RAM for the tmux status bar: used/compressed(swapped), e.g. "RAM 6.4G/3.1G".
# "Used" follows btop / Activity Monitor semantics:
#   macOS: app memory (anonymous - purgeable) + wired + compressor-occupied;
#          second value = physical pages occupied by the compressor
#   Linux: MemTotal - MemAvailable; second value = swap used
# LC_ALL=C: always available and guarantees "." as decimal separator.
export LC_ALL=C

format_bytes() {
  awk -v b="$1" 'BEGIN {
    g = b / 1073741824
    if (g >= 10)     printf "%.0fG", g
    else if (g >= 1) printf "%.1fG", g
    else             printf "%.0fM", b / 1048576
  }'
}

case $(uname -s) in
  Linux)
    read -r total_kb avail_kb swap_total_kb swap_free_kb < <(awk '
      /^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
      /^SwapTotal:/ {st=$2} /^SwapFree:/ {sf=$2}
      END {print t, a, st, sf}' /proc/meminfo)
    used_bytes=$(((total_kb - avail_kb) * 1024))
    comp_bytes=$(((swap_total_kb - swap_free_kb) * 1024))
    ;;
  Darwin)
    read -r used_bytes comp_bytes < <(vm_stat | awk '
      /page size of/                 { ps = $8 }
      /Anonymous pages/              { anon = $3 }
      /Pages purgeable/              { purg = $3 }
      /Pages wired down/             { wired = $4 }
      /Pages occupied by compressor/ { comp = $5 }
      END { printf "%.0f %.0f", (anon - purg + wired + comp) * ps, comp * ps }')
    ;;
  *)
    echo "RAM N/A"
    exit 0
    ;;
esac

echo "RAM $(format_bytes "$used_bytes")/$(format_bytes "$comp_bytes")"
