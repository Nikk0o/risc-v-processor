	.align 2
	.text

	lui sp, %hi(__end_stack)
	addi sp, sp, %lo(__end_stack)

	la a0, main
	csrrw zero, mepc, a0

	la a1, handle_trap
	csrrw zero, mtvec, a1

	li a0, -1
	li a1, 304

	sw a0, 0(a1)
	sw a0, 4(a1)

	lui a1, %hi(plic_1)
	addi a1, a1, %lo(plic_1)

	li a0, 1
	sb a0, 0(a1)
	sb a0, 1(a1)

	li a0, 0x80
	csrrw zero, mie, a0

	li a0, 0
	li a1, 0
	mret
