# ---------------------------------------------------------------------
# Cross-Compiler
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# Operating System
# ---------------------------------------------------------------------

CFLAGS += -Wall \
					-Wextra \
					-Werror \
					-Wshadow \
					-Wwrite-strings \
					-Wconversion \
					-Wcast-qual

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
.PHONY: qemu test

qemu: out/boot_loader.bin
	# Press Alt-2 and type "quit" to exit
	qemu-system-i386 --curses $<

test: out/boot_loader.bin
	shellcheck test/*.sh
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<
