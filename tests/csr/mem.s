	.text
	.align 2
	.globl main

	li t0, 32
	csrrw zero, 0x310, t0

	li t1, 50
	sw t1, 0(zero)

teste:
	li t0, 1

	la t1, teste
	csrrw zero, mtvec, t1

	csrrw zero, 0x310, zero

	li t1, 50
	sw t1, 4(zero)

main:
	j main
