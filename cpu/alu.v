`include "cpu/defines.vh"

module alu(
	input clk,
	input reset,
	input[4:0] alu_op,
	input signed[31:0] r1,
	input signed[31:0] r2,
	output signed[31:0] res,
	output zero,
	output reg illegal_op);

	reg signed[31:0] res_;

	wire is_signed = alu_op != `SUBU && alu_op != `DIVU && alu_op != `REMU;
	wire[31:0] sub = is_signed ? r1 - r2 : $unsigned(r1) - $unsigned(r2);

	wire[31:0] lrshift = r1 >> r2;

	`ifdef RV32M
		wire[31:0] d, rem;

	   assign rem = is_signed ? r1 % r2 : $unsigned(r1) % $unsigned(r2);
	   assign d = is_signed ? r1 / r2 : $unsigned(r1) / $unsigned(r2);
	`endif

	always @(*)
		case (alu_op)
			`ADD:
				res_ <= r1 + r2;
			`SUB:
				res_ <= sub;
			`AND:
				res_ <= r1 & r2;
			`OR:
				res_ <= r1 | r2;
			`XOR:
				res_ <= r1 ^ r2;
			`ifdef RV32M
			`REM:
				res_ <= rem;
			`endif
			`LSHIFT:
				res_ <= r1 << r2;
			`LRSHIFT:
				res_ <= lrshift;
			`ARSHIFT:
				res_ <= r2 >= 0 ? r1 >>> r2 : lrshift;
			`ifdef RV32M
			`MUL:
				res_ <= r1 * r2;
			`DIV:
				res_ <= d;
			`endif
			`SUBU:
				res_ <= sub;
			`ifdef RV32M
			`DIVU:
				res_ <= d;
			`REMU:
				res_ <= rem;
			`endif
			default:
				res_ <= 0;
		endcase

	always @(posedge clk)
		`ifdef RV32M
		if ((alu_op == `DIV || alu_op == `DIVU || alu_op == `REM || alu_op == `REMU) && ~(|r2))
			illegal_op <= 1;
		else
			illegal_op <= 0;
		`else
			illegal_op <= 0;
		`endif

	assign zero = ~(|res_);
	assign res = res_;

endmodule
