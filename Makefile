out:
	mkdir $@

out/boot_sector.bin: src/boot_sector.asm
	nasm -f bin $< -o $@
