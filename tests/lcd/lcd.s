	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p0"
	.file	"lcd.c"
	.globl	init_lcd                        # -- Begin function init_lcd
	.p2align	2
	.type	init_lcd,@function
init_lcd:                               # @init_lcd
# %bb.0:
	addi	sp, sp, -16
	beqz	a0, .LBB0_22
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
	lw	a4, 4(a0)
	slli	a1, a3, 2
	add	a1, a1, a2
	sb	a1, 0(a4)
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
	addi	a3, zero, 4
	bne	a2, a3, .LBB0_11
# %bb.10:
	lw	a2, 4(a0)
	slli	a1, a1, 4
	sb	a1, 0(a2)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
.LBB0_11:
	addi	a1, a1, -1
	andi	a1, a1, 255
	addi	a2, zero, 1
	bltu	a2, a1, .LBB0_14
# %bb.12:
	sw	zero, 8(sp)
	lw	a2, 8(sp)
	lui	a1, %hi(freq)
	lw	a1, %lo(freq)(a1)
	slli	a1, a1, 2
	bgeu	a2, a1, .LBB0_14
.LBB0_13:                               # =>This Inner Loop Header: Depth=1
	lw	a2, 8(sp)
	addi	a2, a2, 1
	sw	a2, 8(sp)
	lw	a2, 8(sp)
	bltu	a2, a1, .LBB0_13
.LBB0_14:
	lw	a1, 4(a0)
	addi	a2, zero, 8
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
	bne	a2, a1, .LBB0_16
# %bb.15:
	lw	a2, 4(a0)
	addi	a3, zero, 128
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lb	a3, 0(a2)
	ori	a3, a3, 4
	sb	a3, 0(a2)
	lw	a2, 0(a0)
	lbu	a3, 0(a2)
	andi	a3, a3, 3
	sb	a3, 0(a2)
.LBB0_16:
	lw	a2, 4(a0)
	addi	a3, zero, 1
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
	bne	a2, a1, .LBB0_18
# %bb.17:
	lw	a1, 4(a0)
	addi	a2, zero, 16
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lb	a2, 0(a1)
	ori	a2, a2, 4
	sb	a2, 0(a1)
	lw	a1, 0(a0)
	lbu	a2, 0(a1)
	andi	a2, a2, 3
	sb	a2, 0(a1)
	j	.LBB0_20
.LBB0_18:
	sw	zero, 12(sp)
	lw	a2, 12(sp)
	lui	a1, %hi(freq)
	lw	a1, %lo(freq)(a1)
	slli	a1, a1, 2
	bgeu	a2, a1, .LBB0_20
.LBB0_19:                               # =>This Inner Loop Header: Depth=1
	lw	a2, 12(sp)
	addi	a2, a2, 1
	sw	a2, 12(sp)
	lw	a2, 12(sp)
	bltu	a2, a1, .LBB0_19
.LBB0_20:
	lw	a1, 4(a0)
	addi	a2, zero, 4
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
	lbu	a1, 10(a0)
	bne	a1, a2, .LBB0_22
# %bb.21:
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
.LBB0_22:
	addi	sp, sp, 16
	ret
.Lfunc_end0:
	.size	init_lcd, .Lfunc_end0-init_lcd
                                        # -- End function
	.globl	clear_screen                    # -- Begin function clear_screen
	.p2align	2
	.type	clear_screen,@function
clear_screen:                           # @clear_screen
# %bb.0:
	addi	sp, sp, -16
	beqz	a0, .LBB1_5
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
	addi	sp, sp, 16
	ret
.LBB1_3:
	sw	zero, 12(sp)
	lw	a1, 12(sp)
	lui	a0, %hi(freq)
	lw	a0, %lo(freq)(a0)
	slli	a0, a0, 2
	bgeu	a1, a0, .LBB1_5
.LBB1_4:                                # =>This Inner Loop Header: Depth=1
	lw	a1, 12(sp)
	addi	a1, a1, 1
	sw	a1, 12(sp)
	lw	a1, 12(sp)
	bltu	a1, a0, .LBB1_4
.LBB1_5:
	addi	sp, sp, 16
	ret
.Lfunc_end1:
	.size	clear_screen, .Lfunc_end1-clear_screen
                                        # -- End function
	.globl	set_ddram_address               # -- Begin function set_ddram_address
	.p2align	2
	.type	set_ddram_address,@function
set_ddram_address:                      # @set_ddram_address
# %bb.0:
	addi	sp, sp, -16
	seqz	a3, a0
	addi	a4, zero, 16
	sltu	a4, a4, a1
	or	a3, a3, a4
	addi	a4, zero, 2
	sltu	a4, a4, a2
	or	a3, a3, a4
	bnez	a3, .LBB2_8
# %bb.1:
	addi	a3, zero, 1
	beq	a2, a3, .LBB2_3
# %bb.2:
	addi	a1, a1, 64
.LBB2_3:
	lw	a3, 4(a0)
	xori	a2, a1, -128
	sb	a2, 0(a3)
	lw	a3, 0(a0)
	sb	zero, 0(a3)
	lw	a3, 0(a0)
	lb	a4, 0(a3)
	ori	a4, a4, 4
	sb	a4, 0(a3)
	lw	a3, 0(a0)
	lbu	a4, 0(a3)
	andi	a4, a4, 3
	sb	a4, 0(a3)
	lbu	a3, 10(a0)
	addi	a4, zero, 4
	bne	a3, a4, .LBB2_5
# %bb.4:
	lw	a3, 4(a0)
	slli	a2, a1, 4
	sb	a2, 0(a3)
	lw	a1, 0(a0)
	lb	a3, 0(a1)
	ori	a3, a3, 4
	sb	a3, 0(a1)
	lw	a0, 0(a0)
	lbu	a1, 0(a0)
	andi	a1, a1, 3
	sb	a1, 0(a0)
.LBB2_5:
	addi	a0, a2, -1
	andi	a0, a0, 255
	addi	a1, zero, 1
	bltu	a1, a0, .LBB2_8
# %bb.6:
	sw	zero, 12(sp)
	lw	a1, 12(sp)
	lui	a0, %hi(freq)
	lw	a0, %lo(freq)(a0)
	slli	a0, a0, 2
	bgeu	a1, a0, .LBB2_8
.LBB2_7:                                # =>This Inner Loop Header: Depth=1
	lw	a1, 12(sp)
	addi	a1, a1, 1
	sw	a1, 12(sp)
	lw	a1, 12(sp)
	bltu	a1, a0, .LBB2_7
.LBB2_8:
	addi	sp, sp, 16
	ret
.Lfunc_end2:
	.size	set_ddram_address, .Lfunc_end2-set_ddram_address
                                        # -- End function
	.type	freq,@object                    # @freq
	.data
	.globl	freq
	.p2align	2
freq:
	.word	27000                           # 0x6978
	.size	freq, 4

	.ident	"clang version 12.0.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
