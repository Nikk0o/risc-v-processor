CC=clang-12
CFLAGS=-target riscv32 -march=rv32im

all:
	$(CC) $(CFLAGS) c/*.c -S
	$(CC) $(CFLAGS) *.s asm/*.s -c
	riscv32-unknown-linux-gnu-ld -T script.ld
	riscv32-unknown-linux-gnu-objcopy -O verilog a.out mem.hex

clean:
	rm *.o; rm *.s
