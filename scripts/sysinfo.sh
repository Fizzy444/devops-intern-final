#!/usr/bin/env bash
set -euo pipefail

printf 'User            : %s (effective UID %s)\n' "$(id -un)" "$(id -u)"
printf 'Hostname        : %s\n' "$(hostname)"
printf 'Kernel release  : %s\n' "$(uname -r)"
printf 'System date     : %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"

printf '\nDisk usage (/):\n'
df -h /

printf '\nMemory usage:\n'
if command -v free >/dev/null 2>&1; then
    free -h
else
    head -n 3 /proc/meminfo
fi

printf '\nDocker daemon   : '
if ! command -v docker >/dev/null 2>&1; then
    printf 'docker CLI not installed\n'
elif docker info >/dev/null 2>&1; then
    printf 'running (server %s)\n' "$(docker version --format '{{.Server.Version}}' 2>/dev/null)"
else
    printf 'not reachable\n'
fi
