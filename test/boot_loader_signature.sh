#!/bin/sh

set -e
BOOT_LOADER="$1"
set -u

if [ -z "$BOOT_LOADER" ]; then
  echo "Usage: $0 <boot loader>" >&2
  exit 1
fi

SIGNATURE="$(xxd -p -seek 0x1fe "$BOOT_LOADER")"

printf "Boot loader signature: %s -> " "$SIGNATURE"

if [ "$SIGNATURE" = "55aa" ]; then
  printf "PASS\\n"
  exit 0
else
  printf "FAIL\\n"
  exit 1
fi
