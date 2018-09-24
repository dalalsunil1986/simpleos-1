.PHONY: qemu test
.DEFAULT_GOAL = qemu

out:
	mkdir $@

out/boot_loader.bin: src/boot_loader.asm src/strings.asm src/gdt.asm | out
	# Output boot sector "raw" format, without additional
	# metadata for linkers, etc
	nasm -I src/ -f bin -D ORIGIN_ADDRESS=0x7c00 -D STACK_SIZE=0x1400 $< -o $@
	xxd $@

qemu: out/boot_loader.bin
	# Press Alt-2 and type "quit" to exit
	qemu-system-i386 --curses $<

test: out/boot_loader.bin
	shellcheck test/*.sh
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<
