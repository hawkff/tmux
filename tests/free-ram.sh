#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/plugins/free-ram.sh"

# Mock only OS inputs; run the real parser and formatter with the current Bash.
uname() { printf '%s\n' "$platform"; }
vm_stat() { printf '%s\n' "$vmstat"; }
sysctl() {
  case $* in
    '-n hw.memsize') [[ -n $memsize_fixture ]] && printf '%s\n' "$memsize_fixture" ;;
    '-n vm.swapusage') [[ -n $swap_fixture ]] && printf '%s\n' "$swap_fixture" ;;
    *) return 1 ;;
  esac
}
awk() {
  if [[ ${2:-} == /proc/meminfo ]]; then
    command awk "$1" <<< "$meminfo"
  else
    command awk "$@"
  fi
}
export -f uname vm_stat sysctl awk

check() {
  local actual
  actual=$("$BASH" "$script")
  if [[ $actual != "$1" ]]; then
    printf 'Expected: %s\nActual:   %s\n' "$1" "$actual" >&2
    exit 1
  fi
}

export platform=Darwin
export memsize_fixture=8589934592
# Include reserved RAM and nonzero purgeable/speculative pages to catch undercounts.
export vmstat='Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free: 8192.
Pages active: 180224.
Pages inactive: 65536.
Pages speculative: 32768.
Pages wired down: 131072.
Pages purgeable: 32768.
File-backed pages: 32768.
Anonymous pages: 245760.
Pages stored in compressor: 262144.
Pages occupied by compressor: 65536.'
export swap_fixture='total = 1024.00M  used = 512.00M  free = 512.00M  (encrypted)'
check 'RAM 7.4G/1.0G/512M'

# Intel page sizes, fractional swap, and failed OS queries.
vmstat=${vmstat/16384 bytes/4096 bytes}
memsize_fixture=2147483648
swap_fixture='total = 4096.00M  used = 3368.96M  free = 727.04M  (encrypted)'
check 'RAM 1.8G/256M/3.3G'
swap_fixture='total = 0.00M  used = 0.00M  free = 0.00M  (encrypted)'
check 'RAM 1.8G/256M/0M'
swap_fixture=''
check 'RAM N/A'
swap_fixture='total = 0.00M  used = 0.00M  free = 0.00M  (encrypted)'
memsize_fixture=''
check 'RAM N/A'
memsize_fixture=2147483648
vmstat=''
check 'RAM N/A'

platform=Linux
export meminfo='MemTotal: 8388608 kB
MemAvailable: 2097152 kB
Buffers: 65536 kB
Cached: 786432 kB
SReclaimable: 262144 kB
Shmem: 262144 kB
SwapTotal: 4194304 kB
SwapFree: 1048576 kB'
check 'RAM 6.0G/768M/3.0G'

# No swap, optional cache fields absent, and the >=10G format.
meminfo='MemTotal: 33554432 kB
MemAvailable: 8388608 kB
Cached: 524288 kB
SwapTotal: 0 kB
SwapFree: 0 kB'
check 'RAM 24G/512M/0M'

# Counters sampled during reclamation must not produce a negative cache.
meminfo+=$'\nShmem: 1048576 kB'
check 'RAM 24G/0M/0M'

platform=FreeBSD
check 'RAM N/A'
printf 'RAM checks passed\n'
