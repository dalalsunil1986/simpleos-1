#!/bin/sh

set -e
BOOT_LOADER="$1"
EXPECTED="$2"
set -u

if [ -z "$BOOT_LOADER" ] || [ -z "$EXPECTED" ]; then
  echo "Usage: $0 <boot loader> <expected>" >&2
  exit 1
fi

BYTES="$(stat -f '%z' "$BOOT_LOADER")"
BITS="$((BYTES * 8))"

printf "Expected size: %s bits\\n" "$EXPECTED"
printf "Boot loader size: %s bits -> " "$BITS"

if [ "$BITS" = "$EXPECTED" ]; then
  printf "PASS\\n"
  exit 0
else
  printf "FAIL\\n"
  exit 1
fi
