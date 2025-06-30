	.align 2
	.globl init
	.text

init:

	la t0, main
	csrrw a0, mepc, t0

	la t1, trap_handler
	csrrw a0, mtvec, t1

	li sp, 256

	mret
