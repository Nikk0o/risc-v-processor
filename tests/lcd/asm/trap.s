	.globl trap_handler
	.align 2
	.text

trap_handler:

	sw x1, 0(zero)
	sw x2, 4(zero)
	sw x3, 8(zero)
	sw x4, 12(zero)
	sw x5, 16(zero)
	sw x6, 20(zero)
	sw x7, 24(zero)
	sw x8, 28(zero)
	sw x9, 32(zero)
	sw x10, 36(zero)
	sw x11, 40(zero)
	sw x12, 44(zero)
	sw x13, 48(zero)
	sw x14, 52(zero)
	sw x15, 56(zero)
	sw x16, 60(zero)
	sw x17, 64(zero)
	sw x18, 68(zero)
	sw x19, 72(zero)
	sw x20, 76(zero)
	sw x21, 80(zero)
	sw x22, 84(zero)
	sw x23, 88(zero)
	sw x24, 92(zero)
	sw x25, 96(zero)
	sw x26, 100(zero)
	sw x27, 104(zero)
	sw x28, 108(zero)
	sw x29, 112(zero)
	sw x30,	116(zero)
	sw x31, 120(zero)

	csrrs t0, mcause, zero
	
	li t1, 11
	beq t0, t1, .handle_ecall

	li t1, 8
	beq t0, t1, .handle_ecall

	li t1, 9
	beq t0, t1, .handle_ecall

	# Handle exception

	j .resume_excecution

.handle_ecall:

	li t0, 1
	bne a0, t0, .resume_excecution
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4

	call init_lcd

.resume_excecution:

	lw x1, 0(zero)
	lw x2, 4(zero)
	lw x3, 8(zero)
	lw x4, 12(zero)
	lw x5, 16(zero)
	lw x6, 20(zero)
	lw x7, 24(zero)
	lw x8, 28(zero)
	lw x9, 32(zero)
	lw x10, 36(zero)
	lw x11, 40(zero)
	lw x12, 44(zero)
	lw x13, 48(zero)
	lw x14, 52(zero)
	lw x15, 56(zero)
	lw x16, 60(zero)
	lw x17, 64(zero)
	lw x18, 68(zero)
	lw x19, 72(zero)
	lw x20, 76(zero)
	lw x21, 80(zero)
	lw x22, 84(zero)
	lw x23, 88(zero)
	lw x24, 92(zero)
	lw x25, 96(zero)
	lw x26, 100(zero)
	lw x27, 104(zero)
	lw x28, 108(zero)
	lw x29, 112(zero)
	lw x30,	116(zero)
	lw x31, 120(zero)

	mret
