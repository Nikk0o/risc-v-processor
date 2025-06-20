	li t0, 0b110000
	csrrw t1, 0x310, t0

	li t0, 1
	li t1, 1
	li s0, 5

start:
	bge t0, s0, store
	addi t0, t0, 1
	mul t1, t1, t0
	j start

store:
	sw t1, 0(zero)
