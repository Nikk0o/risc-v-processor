	.text
	.align 2
	.globl init

init:
	la t0, main

	csrrw t1, mepc, t0
	csrrw t2, medeleg, zero

	mret
