`include "cpu/aluops.vh"

module alu(
	input clk,
	input[4:0] alu_op,
	input signed[31:0] r1,
	input signed[31:0] r2,
	output signed[31:0] res,
	output zero,
	output reg illegal_op = 0);

	reg signed[31:0] res_ = 0;

	always @(*)
		case (alu_op)
			`ADD:
				res_ <= r1 + r2;
			`SUB:
				res_ <= r1 - r2;
			`AND:
				res_ <= r1 & r2;
			`OR:
				res_ <= r1 | r2;
			`XOR:
				res_ <= r1 ^ r2;
			`ifdef RV32M
			`REM:
				res_ <= r1 % r2;
			`endif
			`LSHIFT:
				res_ <= r1 << r2;
			`LRSHIFT:
				res_ <= r1 >> r2;
			`ARSHIFT:
				res_ <= r2 >= 0 ? r1 >>> r2 : r1 >> r2;
			`ifdef RV32M
			`MUL:
				res_ <= r1 * r2;
			`DIV:
				res_ <= r1 / r2;
			`endif
			`SUBU:
				res_ <= (r1 >= 0 ? r1 : -r1) - (r2 >= 0 ? r2 : -r2);
			`ifdef RV32M
			`DIVU:
				res_ <= (r1 >= 0 ? r1 : -r1) / (r2 >= 0 ? r2 : -r2);
			`REMU:
				res_ <= (r1 >= 0 ? r1 : -r1) % (r2 >= 0 ? r2 : -r2);*/
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

	assign zero = res_ == 0;
	assign res = res_;

endmodule
