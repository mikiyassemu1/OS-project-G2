all: boot.img

boot.img: boot.bin loader.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=loader.bin of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "✅ boot.img ready"

boot.bin: boot.asm
	nasm -f bin boot.asm -o $@

loader.bin: loader.asm
	nasm -f bin loader.asm -o $@

run: boot.img
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -f *.bin *.img
