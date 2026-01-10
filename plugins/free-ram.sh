#!/usr/bin/env bash
# Cross-platform script to display free/compressed/total RAM

format_bytes() {
  local bytes=$1
  local gb=$(awk -v b="$bytes" 'BEGIN { printf "%.1f", b/1024/1024/1024 }')
  if awk -v g="$gb" 'BEGIN { exit (g >= 1) ? 0 : 1 }'; then
    echo "${gb}G"
  else
    awk -v b="$bytes" 'BEGIN { printf "%.0fM", b/1024/1024 }'
  fi
}

case $(uname -s) in
  Linux)
    free_kb=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
    total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    # Linux doesn't have compressed memory in the same way, show cached instead
    cached_kb=$(awk '/^Cached:/ {print $2}' /proc/meminfo)
    free=$(format_bytes $((free_kb * 1024)))
    compressed=$(format_bytes $((cached_kb * 1024)))
    total=$(format_bytes $((total_kb * 1024)))
    ;;
  Darwin)
    pagesize=$(pagesize)
    stats=$(vm_stat)
    free_pages=$(echo "$stats" | awk '/Pages free:/ {gsub(/\./,"",$3); print $3}')
    compressed_pages=$(echo "$stats" | awk '/Pages stored in compressor:/ {gsub(/\./,"",$5); print $5}')
    total_bytes=$(sysctl -n hw.memsize)
    free=$(format_bytes $((free_pages * pagesize)))
    compressed=$(format_bytes $((compressed_pages * pagesize)))
    total=$(format_bytes "$total_bytes")
    ;;
  *)
    free="N/A"
    compressed="N/A"
    total="N/A"
    ;;
esac

echo "RAM ${free}/${compressed}/${total}"
