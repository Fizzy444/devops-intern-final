#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://localhost:8080}"

if ! command -v curl >/dev/null 2>&1; then
    printf 'FAIL: curl is required but not installed\n' >&2
    exit 2
fi

status="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url")" || status="000"

if [ "$status" = "200" ]; then
    printf 'OK: %s returned HTTP %s\n' "$url" "$status"
    exit 0
fi

if [ "$status" = "000" ]; then
    printf 'FAIL: %s is unreachable (connection refused, DNS failure or timeout)\n' "$url" >&2
else
    printf 'FAIL: %s returned HTTP %s, expected 200\n' "$url" "$status" >&2
fi
exit 1
