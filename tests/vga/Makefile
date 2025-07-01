CC=clang
CFLAGS=-fno-pic -march=rv32i -target riscv32

all:
	$(CC) $(CFLAGS) c/main.c -S
	$(CC) $(CFLAGS) main.s asm/init.s -c
	$(LD) -T script.ld
	riscv32-unknown-linux-gnu-objcopy -O verilog -j .text out.elf inst_mem.hex

clean:
	rm *.o; rm *.s; rm *.elf
