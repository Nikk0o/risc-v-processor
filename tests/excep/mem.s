	## Test traps

	# Set endianness to big endian
	li t0, 64
	csrrw t1, mstatus, t0

	csrrw zero, mstatus, zero # This should not execute

	# Store mstatus
	csrrs t1, mstatus, zero
	sw t1, 0(zero)
	la t0, start
	csrrw t1, mepc, t0
    la t0, handle_trap
    csrrw t1, mtvec, t0

	li t0, 0
	li t1, 0

	mret

handle_trap:
	li a3, 0
	bne a0, a3, check_big_e

	# Change endianess to little endian
	li a3, 0
	csrrw a3, mstatus, a3
	mret

check_big_e:
	li a3, 1
	bne a0, a3, return_handle

	# Change endianness to big endian
	li a3, 64
	csrrw a3, mstatus, a3

return_handle:
	mret


start:
	li t0, 5000
	li a0, 0
	ecall
	sw t0, 0(zero)
	li a0, 1
	ecall
	sw t0, 4(zero)
halt:
	j halt
