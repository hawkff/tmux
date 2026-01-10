#!/usr/bin/env bash
# Cross-platform script to display free/total RAM

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
    free=$(format_bytes $((free_kb * 1024)))
    total=$(format_bytes $((total_kb * 1024)))
    ;;
  Darwin)
    pagesize=$(pagesize)
    free_pages=$(vm_stat | awk '/Pages free:/ {gsub(/\./,"",$3); print $3}')
    total_bytes=$(sysctl -n hw.memsize)
    free=$(format_bytes $((free_pages * pagesize)))
    total=$(format_bytes "$total_bytes")
    ;;
  *)
    free="N/A"
    total="N/A"
    ;;
esac

echo "RAM ${free}/${total}"
