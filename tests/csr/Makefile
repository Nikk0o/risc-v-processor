all:
	clang -target riscv32 -march=rv32im mem.s -c
	riscv32-unknown-linux-gnu-ld -T script.ld
	riscv32-unknown-linux-gnu-objcopy -O verilog a.out mem.hex -j .text
