	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p0"
	.file	"ecall.c"
	.globl	invoke_ecall                    # -- Begin function invoke_ecall
	.p2align	2
	.type	invoke_ecall,@function
invoke_ecall:                           # @invoke_ecall
# %bb.0:
	#APP
	ecall	

	#NO_APP
	ret
.Lfunc_end0:
	.size	invoke_ecall, .Lfunc_end0-invoke_ecall
                                        # -- End function
	.ident	"clang version 12.0.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
