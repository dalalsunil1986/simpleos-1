# ---------------------------------------------------------------------
# Cross-Compiler
# ---------------------------------------------------------------------

HOST_CC ?= gcc-8
HOST_CXX ?= g++-8

.tmp:
	mkdir $@

.toolchain:
	mkdir $@

CROSS_COMPILER_TARGET = i386-elf
CROSS_COMPILER_PREFIX = $(shell pwd)/.toolchain

crosscompiler: | .tmp .toolchain
	mkdir -p $(word 1,$|)/binutils-build
	cd $(word 1,$|)/binutils-build && CC=$(HOST_CC) ../../deps/binutils/configure \
		--target=$(CROSS_COMPILER_TARGET) \
		--prefix=$(CROSS_COMPILER_PREFIX) \
		--disable-werror
	cd $(word 1,$|)/binutils-build && make all install
	mkdir -p $(word 1,$|)/gcc-build
	cd $(word 1,$|)/gcc-build && PATH=$(CROSS_COMPILER_PREFIX)/bin:$(PATH) \
		CC=$(HOST_CC) CXX=$(HOST_CXX) ../../deps/gcc/configure \
		--target=$(CROSS_COMPILER_TARGET) \
		--prefix=$(CROSS_COMPILER_PREFIX) \
		--disable-libssp \
		--disable-libstdcxx \
		--enable-languages=c \
		--without-headers
	cd $(word 1,$|)/gcc-build && make \
		all-gcc all-target-libgcc install-gcc install-target-libgcc

# ---------------------------------------------------------------------
# Operating System
# ---------------------------------------------------------------------

# CFLAGS += -Wall \
					# -Wextra \
					# -Werror \
					# -Wshadow \
					# -Wwrite-strings \
					# -Wconversion \
					# -Wcast-qual

BOOT_LOADER_HELPERS_ASM = \
	src/strings_bios.asm \
	src/strings_vga.asm \
	src/gdt.asm \
	src/protected_mode.asm

BOOT_LOADER_ORIGIN_ADDRESS = 0x7c00
BOOT_LOADER_STACK_SIZE = 0x1400
# TODO: Why? Isn't this too low?
KERNEL_ORIGIN_ADDRESS = 0x1000

out:
	mkdir $@

out/boot_loader.bin: src/boot_loader.asm $(BOOT_LOADER_HELPERS_ASM) | out
	# Output boot sector "raw" format, without additional
	# metadata for linkers, etc
	nasm -I src/ -f bin \
		-D ORIGIN_ADDRESS=$(BOOT_LOADER_ORIGIN_ADDRESS) \
		-D STACK_SIZE=$(BOOT_LOADER_STACK_SIZE) \
		-D KERNEL_OFFSET=$(KERNEL_ORIGIN_ADDRESS) \
		$< -o $@
	xxd $@

out/kernel.o: src/kernel.c | out
	# A free-standing environment assumes nothing about typical
	# built-in C functions. Without it, the compiler might see
	# something like "strcpy" and optimise such call away with
	# special intructions. Basically, behave as if there is no
	# concept of a standard library.
	gcc $(CFLAGS) -ffreestanding -c $< -o $@

out/kernel.bin: out/kernel.o
	# TODO: -Ttext seems to be the origin address where the kernel
	# will be loaded. Exactly the same as [org 0x1000] in NASM
	ld -o $@ -Ttext 0x1000 $< --oformat binary

out/image.bin: out/boot_loader.bin out/kernel.bin
	cat $* > $@

# ---------------------------------------------------------------------
# Phony Targets
# ---------------------------------------------------------------------

.DEFAULT_GOAL = qemu
.PHONY: qemu test distclean crosscompiler

qemu: out/boot_loader.bin
	# Press Alt-2 and type "quit" to exit
	qemu-system-i386 --curses $<

test: out/boot_loader.bin
	shellcheck test/*.sh
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<

distclean:
	rm -rf out
	rm -rf .toolchain
	rm -rf .tmp
