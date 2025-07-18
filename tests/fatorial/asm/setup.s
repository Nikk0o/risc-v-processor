	.align 2
	.text

	lui sp, %hi(__end_stack)
	addi sp, sp, %lo(__end_stack)

	call main
