# ---------------------------------------------------------------------
# Cross-Compiler
# ---------------------------------------------------------------------

# Older versions of gcc don't seem to build on clang on macOS
# See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81037
HOST_CC ?= gcc-8
HOST_CXX ?= g++-8

.tmp:
	mkdir $@

# TODO: Why elf?
CROSS_COMPILER_TARGET = i386-elf

# The installation prefix directory for the toolchain
CROSS_COMPILER_PREFIX = $(shell pwd)/.toolchain

crosscompiler: | .tmp
	mkdir -p $(word 1,$|)/binutils-build $(CROSS_COMPILER_PREFIX)
	# --disable-werror:
	#     Disable the -Werror compiler flag, which turns
	#     warnings into errors
	cd $(word 1,$|)/binutils-build && CC=$(HOST_CC) ../../deps/binutils/configure \
		--target=$(CROSS_COMPILER_TARGET) \
		--prefix=$(CROSS_COMPILER_PREFIX) \
		--disable-werror
	cd $(word 1,$|)/binutils-build && make all install
	mkdir -p $(word 1,$|)/gcc-build
	cd $(word 1,$|)/gcc-build && PATH=$(CROSS_COMPILER_PREFIX)/bin:$(PATH) \
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
		CC=$(HOST_CC) CXX=$(HOST_CXX) ../../deps/gcc/configure \
		--target=$(CROSS_COMPILER_TARGET) \
		--prefix=$(CROSS_COMPILER_PREFIX) \
		--disable-libssp \
		--enable-languages=c \
		--without-headers
	cd $(word 1,$|)/gcc-build && make \
		all-gcc all-target-libgcc install-gcc install-target-libgcc

# ---------------------------------------------------------------------
# Operating System
# ---------------------------------------------------------------------

# -ffreestanding
#     A free-standing environment assumes nothing about typical
#     built-in C functions. Without it, the compiler might see
#     something like "strcpy" and optimise such call away with
#     special intructions. Basically, behave as if there is no
#     concept of a standard library.
# -W
#     Enable various common compiler warnings
# -Wall
#			Enable all general compiler warnings
#	-Wextra
#			Enable all extra compiler warnings
#	-Werror
#			Turn all warnings into errors
# -Wshadow
#			Warn about variable shadowing (re-definition of a variable
#			from an outer scope)
#	-Wwrite-strings
#			Implicitly give a `const` qualifier to all string constants
#			in the program
#	-Wconversion
#			Warn about implicit conversions
#	-Wcast-qual
#			Warn about pointer casting that drops qualifiers such as
#			`const`
CROSS_COMPILER_CFLAGS = \
	-ffreestanding \
	-W \
	-Wall \
	-Wextra \
	-Werror \
	-Wshadow \
	-Wwrite-strings \
	-Wconversion \
	-Wcast-qual

BOOT_LOADER_HELPERS_ASM = \
	src/strings_bios.asm \
	src/strings_vga.asm \
	src/bios_io.asm \
	src/gdt.asm \
	src/protected_mode.asm

# The BIOS automatically loads boot loaders into this
# address, we can't put something else here
BOOT_LOADER_ORIGIN_ADDRESS = 0x7c00

# A setting that we control
BOOT_LOADER_STACK_SIZE = 0x1400

# TODO: Why? Isn't this too low? (this is the second sector, at byte 512)
# Would it be better to put it 512 bytes after the boot loader origin
# address? ie 0x7c00 + (512 * 8)?
# TODO: These are the same, but don't really need to
KERNEL_ORIGIN_ADDRESS = 0x1000
KERNEL_DISK_ADDRESS = 0x1000
# 16 sectors should be enough for our kernel
# This value should be a multiple of 4096 (the sector size)
# TODO: Write a test script that ensures the kernel
# doesn't exceed this value
KERNEL_DISK_SIZE = 0x10000

out:
	mkdir $@

out/boot_loader.bin: src/boot_loader.asm $(BOOT_LOADER_HELPERS_ASM) | out
	# Output boot sector "raw" format, without additional
	# metadata for linkers, etc
	nasm -I src/ -f bin \
		-D ORIGIN_ADDRESS=$(BOOT_LOADER_ORIGIN_ADDRESS) \
		-D STACK_SIZE=$(BOOT_LOADER_STACK_SIZE) \
		-D KERNEL_ORIGIN_ADDRESS=$(KERNEL_ORIGIN_ADDRESS) \
		-D KERNEL_DISK_ADDRESS=$(KERNEL_DISK_ADDRESS) \
		-D KERNEL_DISK_SIZE=$(KERNEL_DISK_SIZE) \
		$< -o $@
	xxd $@

out/kernel.o: src/kernel.c | out
	$(CROSS_COMPILER_PREFIX)/bin/$(CROSS_COMPILER_TARGET)-gcc \
		$(CROSS_COMPILER_CFLAGS) -c $< -o $@

out/kernel.bin: out/kernel.o
	# TODO: -Ttext seems to be the origin address where the kernel
	# will be loaded. Exactly the same as [org 0x1000] in NASM
	# Doesn't seem to be making any difference here
	$(CROSS_COMPILER_PREFIX)/bin/$(CROSS_COMPILER_TARGET)-ld \
		-o $@ -Ttext $(KERNEL_ORIGIN_ADDRESS) $< --oformat binary

# For debugging purposes
out/kernel.asm: out/kernel.bin
	# Set the processor mode to 32-bit. Remember that the kernel
	# always runs in protected mode, so we don't have to worry
	# about part of the boot loader being written with 16-bit
	# instructions
	ndisasm -b 32 $< > $@

# The BIOS only loads the boot loader, so we must manually
# copy the kernel machine code into memory. In order to simplify
# the loading routine, we put the kernel right after the boot
# loader, so we always know where to look
out/image.bin: out/boot_loader.bin out/kernel.bin
	cat $^ > $@

# ---------------------------------------------------------------------
# Phony Targets
# ---------------------------------------------------------------------

.DEFAULT_GOAL = qemu
.PHONY: qemu test clean distclean crosscompiler

qemu: out/image.bin
	# Press Alt-2 and type "quit" to exit
	# -fda: Set the image as floppy disk 0
	qemu-system-i386 --curses -drive format=raw,file=$<,index=0,if=floppy

test: out/boot_loader.bin
	shellcheck test/*.sh
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<

clean:
	rm -rf out

distclean: clean
	rm -rf .toolchain
	rm -rf .tmp
