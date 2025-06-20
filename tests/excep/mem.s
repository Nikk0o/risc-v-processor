	## Test system calls

	la t0, handle_excep
	la t1, start
	csrrw t2, mtvec, t0
	csrrw t2, mepc, t1
	li t0, 0
	li t1, 0
	li t2, 0
	mret

	# Main program
start:
	li s0, 5
	beq a0, s0, aua
	addi a0, a0, 1
	addi a1, a1, 1
	ecall
aua:
	li t1, 1
	sb t1, 0(a0)
uaca:
	# halt
	j uaca

handle_excep:
	sb a0, 0(a1)
	csrrs a2, 0x310, zero
	csrrs a3, mstatus, zero
	xori a2, a2, 0x30
	xori a3, a3, 64
	csrrw a2, 0x310, a2
	csrrw a3, mstatus, a3
	mret
