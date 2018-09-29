# ---------------------------------------------------------------------
# Cross-Compiler
# ---------------------------------------------------------------------

# TODO: Why elf?
KERNEL_BINARY_FORMAT = elf
CROSS_COMPILER_TARGET = i386-$(KERNEL_BINARY_FORMAT)

# ---------------------------------------------------------------------
# Operating System
# ---------------------------------------------------------------------

C_SOURCES = $(wildcard src/kernel/*.c)
C_HEADERS = $(wildcard src/kernel/*.h)
C_OBJECTS = $(patsubst src/kernel/%.c,out/%.o,$(C_SOURCES))

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

# The BIOS automatically loads boot loaders into this
# address, we can't put something else here
BOOT_LOADER_ORIGIN_ADDRESS = 0x7c00

# The boot loader should be one sector
BOOT_LOADER_DISK_SIZE = 0x1000

# A setting that we control
BOOT_LOADER_STACK_SIZE = 0x1400

# The address where the kernel will be loaded in memory, relative
# from the boot loader origin address, as we're setting [org ADDRESS]
# in the boot loader. In this case, we will also load the kernel
# right after the boot loader.
KERNEL_ORIGIN_ADDRESS = $(BOOT_LOADER_DISK_SIZE)

# The address in the disk where we expect to find the kernel.
# We append the kernel to the boot loader, so this should be
# the second sector of the drive
KERNEL_DISK_ADDRESS = $(BOOT_LOADER_DISK_SIZE)

# 16 sectors should be enough for our kernel
# This value should be a multiple of 4096 (the sector size)
KERNEL_DISK_SIZE = 65536

out:
	mkdir $@

out/boot_loader.bin: src/boot/main.asm $(wildcard src/boot/utils/*.asm) | out
	# Output boot sector "raw" format, without additional
	# metadata for linkers, etc
	nasm -I src/boot/ -f bin \
		-D BOOT_LOADER_ORIGIN_ADDRESS=$(BOOT_LOADER_ORIGIN_ADDRESS) \
		-D STACK_SIZE=$(BOOT_LOADER_STACK_SIZE) \
		-D KERNEL_ORIGIN_ADDRESS=$(KERNEL_ORIGIN_ADDRESS) \
		-D KERNEL_DISK_ADDRESS=$(KERNEL_DISK_ADDRESS) \
		-D KERNEL_DISK_SIZE=$(KERNEL_DISK_SIZE) \
		$< -o $@
	xxd $@

out/%.o: src/kernel/%.c $(C_HEADERS)
	$(CROSS_COMPILER_TARGET)-gcc \
		$(CROSS_COMPILER_CFLAGS) -c $< -o $@

# This piece of assembly will be linked at the beginning
# of the compiled C code, therefore we must built it with
# the same binary format.
out/kernel_entry.o: src/kernel/entry.asm
	nasm $< -f $(KERNEL_BINARY_FORMAT) -o $@

out/kernel.bin: out/kernel_entry.o $(C_OBJECTS)
	# -Ttext <address>:
	#     Set the address of the text section, which contains the
	#     execute instructions from the kernel. We set this to the
	#     address that the boot loader will load the kernel to.
	#     This option causes all other addresses in the binary to
	#     be relative to this address, effectively mirroring what
	#     the NASM [org ADDRESS] directive did on the boot loader
	$(CROSS_COMPILER_TARGET)-ld \
		-o $@ -Ttext $(KERNEL_ORIGIN_ADDRESS) $^ --oformat binary

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
.PHONY: qemu lint test clean distclean crosscompiler

qemu: out/image.bin
	# Press Alt-2 and type "quit" to exit
	# -fda: Set the image as floppy disk 0
	qemu-system-i386 --curses -drive format=raw,file=$<,index=0,if=floppy

lint:
	shellcheck test/*.sh
	vera++ --show-rule --summary --error $(C_SOURCES) $(C_HEADERS)

test: lint out/boot_loader.bin out/kernel.bin
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<
	./test/kernel_size.sh $(word 2,$^) $(KERNEL_DISK_SIZE)

clean:
	rm -rf out

distclean: clean
	rm -rf .toolchain
