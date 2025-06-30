	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p0"
	.file	"lcd.c"
	.globl	init_lcd                        # -- Begin function init_lcd
	.p2align	2
	.type	init_lcd,@function
init_lcd:                               # @init_lcd
# %bb.0:
	beqz	a0, .LBB0_17
# %bb.1:
	lw	a4, 4(a0)
	addi	a2, zero, 8
	sb	a2, 10(a0)
	addi	a6, zero, 48
	sb	a6, 0(a4)
	lw	a4, 0(a0)
	sb	zero, 0(a4)
	lw	a4, 0(a0)
	lb	a5, 0(a4)
	ori	a5, a5, 4
	sb	a5, 0(a4)
	lw	a4, 0(a0)
	lbu	a5, 0(a4)
	andi	a5, a5, 3
	sb	a5, 0(a4)
	lbu	a5, 10(a0)
	addi	a4, zero, 4
	bne	a5, a4, .LBB0_3
# %bb.2:
	lw	a5, 4(a0)
	sb	zero, 0(a5)
	lw	a5, 0(a0)
	lb	a2, 0(a5)
	ori	a2, a2, 4
	sb	a2, 0(a5)
	lw	a2, 0(a0)
	lbu	a5, 0(a2)
	andi	a5, a5, 3
	sb	a5, 0(a2)
.LBB0_3:
	lw	a2, 4(a0)
	sb	a6, 0(a2)
	lw	a2, 0(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a5, 0(a2)
	ori	a5, a5, 4
	sb	a5, 0(a2)
	lw	a2, 0(a0)
	lbu	a5, 0(a2)
	andi	a5, a5, 3
	sb	a5, 0(a2)
	lbu	a2, 10(a0)
	bne	a2, a4, .LBB0_5
# %bb.4:
	lw	a2, 4(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a4, 0(a2)
	ori	a4, a4, 4
	sb	a4, 0(a2)
	lw	a2, 0(a0)
	lbu	a4, 0(a2)
	andi	a4, a4, 3
	sb	a4, 0(a2)
.LBB0_5:
	lw	a2, 4(a0)
	addi	a4, zero, 48
	sb	a4, 0(a2)
	lw	a2, 0(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a4, 0(a2)
	ori	a4, a4, 4
	sb	a4, 0(a2)
	lw	a2, 0(a0)
	lbu	a4, 0(a2)
	andi	a4, a4, 3
	sb	a4, 0(a2)
	lbu	a2, 10(a0)
	addi	a4, zero, 4
	bne	a2, a4, .LBB0_7
# %bb.6:
	lw	a2, 4(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a4, 0(a2)
	ori	a4, a4, 4
	sb	a4, 0(a2)
	lw	a2, 0(a0)
	lbu	a4, 0(a2)
	andi	a4, a4, 3
	sb	a4, 0(a2)
.LBB0_7:
	sb	a1, 10(a0)
	addi	a4, zero, 8
	addi	a2, zero, 56
	beq	a1, a4, .LBB0_9
# %bb.8:
	addi	a2, zero, 48
.LBB0_9:
	lw	a1, 4(a0)
	slli	a3, a3, 2
	add	a2, a3, a2
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	sb	zero, 0(a1)
	lw	a1, 0(a0)
	lb	a3, 0(a1)
	ori	a3, a3, 4
	sb	a3, 0(a1)
	lw	a1, 0(a0)
	lbu	a3, 0(a1)
	andi	a3, a3, 3
	sb	a3, 0(a1)
	lbu	a3, 10(a0)
	addi	a1, zero, 4
	bne	a3, a1, .LBB0_11
# %bb.10:
	lw	a3, 4(a0)
	slli	a2, a2, 4
	sb	a2, 0(a3)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
.LBB0_11:
	lw	a2, 4(a0)
	addi	a3, zero, 8
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
	lbu	a2, 10(a0)
	bne	a2, a1, .LBB0_13
# %bb.12:
	lw	a1, 4(a0)
	addi	a2, zero, 128
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lbu	a2, 0(a1)
	andi	a2, a2, 3
	sb	a2, 0(a1)
.LBB0_13:
	lw	a1, 4(a0)
	addi	a2, zero, 1
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	sb	zero, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lbu	a2, 0(a1)
	andi	a2, a2, 3
	sb	a2, 0(a1)
	lbu	a2, 10(a0)
	addi	a1, zero, 4
	bne	a2, a1, .LBB0_15
# %bb.14:
	lw	a2, 4(a0)
	addi	a3, zero, 16
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
.LBB0_15:
	lw	a2, 4(a0)
	sb	a1, 0(a2)
	lw	a2, 0(a0)
	sb	zero, 0(a2)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
	lbu	a2, 10(a0)
	bne	a2, a1, .LBB0_17
# %bb.16:
	lw	a1, 4(a0)
	addi	a2, zero, 64
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a0, 0(a0)
	lbu	a1, 0(a0)
	andi	a1, a1, 3
	sb	a1, 0(a0)
.LBB0_17:
	ret
.Lfunc_end0:
	.size	init_lcd, .Lfunc_end0-init_lcd
                                        # -- End function
	.globl	clear_screen                    # -- Begin function clear_screen
	.p2align	2
	.type	clear_screen,@function
clear_screen:                           # @clear_screen
# %bb.0:
	beqz	a0, .LBB1_3
# %bb.1:
	lw	a1, 4(a0)
	addi	a2, zero, 1
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	sb	zero, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lbu	a2, 0(a1)
	andi	a2, a2, 3
	sb	a2, 0(a1)
	lbu	a1, 10(a0)
	addi	a2, zero, 4
	bne	a1, a2, .LBB1_3
# %bb.2:
	lw	a1, 4(a0)
	addi	a2, zero, 16
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a0, 0(a0)
	lbu	a1, 0(a0)
	andi	a1, a1, 3
	sb	a1, 0(a0)
.LBB1_3:
	ret
.Lfunc_end1:
	.size	clear_screen, .Lfunc_end1-clear_screen
                                        # -- End function
	.ident	"clang version 12.0.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
