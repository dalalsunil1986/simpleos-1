#!/bin/sh

set -e
BOOT_LOADER="$1"
set -u

if [ -z "$BOOT_LOADER" ]; then
  echo "Usage: $0 <boot loader>" >&2
  exit 1
fi

BYTES="$(stat -f '%z' "$BOOT_LOADER")"

printf "Boot loader size: %s bytes -> " "$BYTES"

if [ "$BYTES" = "512" ]; then
  printf "PASS\\n"
  exit 0
else
  printf "FAIL\\n"
  exit 1
fi
