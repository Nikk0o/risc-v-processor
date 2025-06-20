	## Test endianness change right after load or store

	li t2, 0

	# Set endianness to big endian
	li t0, 0x30
	csrrw t1, 0x310, t0

	# Store a word in big endian
	li t0, 9
	sw t0, 0(zero)

	# Change endianness to little endian
	csrrw t1, 0x310, t2

	# Store a word in little endian
	li t0, 0x30
	sw t0, 4(zero)

	## Test write to CSR after branch or jump

	li t0, 0x30
	beq t0, t1, a
	csrrw t1, mtvec, t0

	j b

a:
	sw t0, 8(zero)

b:
	sw t0, 12(zero)
