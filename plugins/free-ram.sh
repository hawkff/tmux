#!/usr/bin/env bash
# RAM for the tmux status bar: used/cached files/swap used.
# macOS: physical - free - file-backed (includes system-reserved RAM);
#        file-backed + purgeable; actual swap usage, not the in-RAM compressor.
# Linux: MemTotal - MemAvailable; Cached + SReclaimable - Shmem; swap used.
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
    read -r total_kb avail_kb cached_kb swap_total_kb swap_free_kb < <(awk '
      /^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
      /^Cached:/ {c=$2} /^SReclaimable:/ {r=$2} /^Shmem:/ {s=$2}
      /^SwapTotal:/ {st=$2} /^SwapFree:/ {sf=$2}
      END {cache=c+r-s; print t, a, (cache > 0 ? cache : 0), st, sf}' /proc/meminfo)
    used_bytes=$(((total_kb - avail_kb) * 1024))
    cached_bytes=$((cached_kb * 1024))
    swap_bytes=$(((swap_total_kb - swap_free_kb) * 1024))
    ;;
  Darwin)
    total_bytes=$(sysctl -n hw.memsize) || { echo "RAM N/A"; exit 0; }
    # vm_stat's "Pages free" already excludes speculative pages.
    read -r used_bytes cached_bytes < <(vm_stat | awk -v total="$total_bytes" '
      /page size of/        { ps = $8 }
      /Pages free:/         { free = $3 }
      /Pages purgeable:/    { purg = $3 }
      /File-backed pages:/  { file = $3 }
      END {
        if (!ps) exit 1
        printf "%.0f %.0f\n", total - (free + file) * ps, (file + purg) * ps
      }') || { echo "RAM N/A"; exit 0; }
    swap_usage=$(sysctl -n vm.swapusage) || { echo "RAM N/A"; exit 0; }
    # macOS reports vm.swapusage in MiB, including the fractional part.
    swap_bytes=$(awk '{printf "%.0f", $6 * 1048576}' <<< "$swap_usage")
    ;;
  *)
    echo "RAM N/A"
    exit 0
    ;;
esac

echo "RAM $(format_bytes "$used_bytes")/$(format_bytes "$cached_bytes")/$(format_bytes "$swap_bytes")"
