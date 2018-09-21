.PHONY: qemu test

out:
	mkdir $@

out/boot_sector.bin: src/boot_sector.asm | out
	# Output boot sector "raw" format, without additional
	# metadata for linkers, etc
	nasm -f bin $< -o $@
	hexdump -x $@

qemu: out/boot_sector.bin
	# Press Alt-2 and type "quit" to exit
	qemu-system-i386 --curses $<

test: out/boot_sector.bin
	shellcheck test/*.sh
	./test/boot_loader_size.sh $<
	./test/boot_loader_signature.sh $<
