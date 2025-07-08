CC=clang
CFLAGS=-target riscv32 -march=rv32im -fno-plt

all:
	$(CC) $(CFLAGS) c/main.c -S
	$(CC) $(CFLAGS) asm/*.s *.s -c
	riscv32-unknown-linux-gnu-ld -T script.ld
	riscv32-unknown-linux-gnu-objcopy -O verilog out.elf mem.hex

clean:
	rm *.elf; rm *.o; rm *.s
