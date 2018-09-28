#!/bin/sh

set -e
KERNEL="$1"
EXPECTED="$2"
set -u

if [ -z "$KERNEL" ] || [ -z "$EXPECTED" ]; then
  echo "Usage: $0 <kernel> <expected>" >&2
  exit 1
fi

BYTES="$(stat -f '%z' "$KERNEL")"

printf "Expected size: %s\\n" "$EXPECTED"
printf "Kernel size: %s -> " "$BYTES"

if [ "$BYTES" -gt "$EXPECTED" ]; then
  printf "FAIL\\n"
  exit 1
else
  printf "PASS\\n"
  exit 0
fi
