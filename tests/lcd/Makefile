CC=clang
LD=riscv32-unknown-linux-gnu-ld
CFLAGS=-fno-pic -march=rv32i -target riscv32

generate_mem:
	$(CC) c/*.c $(CFLAGS) -S
	$(CC) *.s asm/*.s $(CFLAGS) -c
	$(LD) -T script.ld
	riscv32-unknown-linux-gnu-objcopy -j .text -O verilog out.elf inst_mem.hex

clean:
	rm *.s; rm *.o; rm *.elf
