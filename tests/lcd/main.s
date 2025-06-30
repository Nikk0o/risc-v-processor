	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p0"
	.file	"main.c"
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	addi	a0, zero, 260
	sw	a0, 132(zero)
	addi	a0, zero, 261
	sw	a0, 136(zero)
	addi	a0, zero, 1
	addi	a1, zero, 132
	addi	a2, zero, 8
	addi	a3, zero, 1
	addi	a4, zero, 1
	call	invoke_ecall
	sw	zero, 8(sp)
	sw	zero, 8(sp)
	mv	a0, zero
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
                                        # -- End function
	.ident	"clang version 12.0.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
