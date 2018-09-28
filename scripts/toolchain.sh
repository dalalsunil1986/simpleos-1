#!/bin/sh

set -x
set -eE
ARGV_TARGET="$1"
ARGV_PREFIX="$2"
set -u

if [ -z "$ARGV_TARGET" ] || [ -z "$ARGV_PREFIX" ]; then
  echo "Usage: $0 <target> <prefix>" >&2
  exit 1
fi

set +u
if [ -z "$CC" ] || [ -z "$CXX" ]; then
set -u
  echo "Please set the CC and CXX environment variables" >&2
  exit 1
fi

TEMP="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP"
}

trap cleanup EXIT
trap cleanup INT
trap cleanup TERM
trap cleanup QUIT
trap cleanup ABRT

CWD="$(pwd)"
BINUTILS_TEMP="$TEMP/binutils-build"
GCC_TEMP="$TEMP/gcc-build"

mkdir -p "$ARGV_PREFIX" "$BINUTILS_TEMP" "$GCC_TEMP"

cd "$BINUTILS_TEMP"
# --disable-werror:
#     Disable the -Werror compiler flag, which turns
#     warnings into errors
"$CWD/deps/binutils/configure" \
  --target="$ARGV_TARGET" \
  --prefix="$ARGV_PREFIX" \
  --disable-werror
make all install

cd "$GCC_TEMP"
# --disable-libssp:
#     This is the "Stack Smashing Protector", a GCC feature
#     to automatically re-write code to attempt to detect
#     stack buffer overruns. We disable this feature as we
#     don't want GCC to modify our code at all.
#     See: https://wiki.osdev.org/Stack_Smashing_Protector
# --enable-languages=c:
#     We're only interested in the C language
# --without-headers:
#     Don't rely on any libc library from the target
PATH="$ARGV_PREFIX/bin:$PATH" "$CWD/deps/gcc/configure" \
  --target="$ARGV_TARGET" \
  --prefix="$ARGV_PREFIX" \
  --disable-libssp \
  --enable-languages=c \
  --without-headers
make all-gcc all-target-libgcc install-gcc install-target-libgcc
