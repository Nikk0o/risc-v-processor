module alu(
	input clk,
	input[4:0] alu_op,
	input signed[31:0] r1,
	input signed[31:0] r2,
	output signed[31:0] res,
	output zero,
	output reg illegal_op);

	reg signed[31:0] res_ = 0;
	reg signed[31:0] res__ = 0;

	always @(posedge clk)
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
			`REM:
				res_ <= r1 % r2;
			`LSHIFT:
				res_ <= r1 << r2;
			`LRSHIFT:
				res_ <= r1 >> r2;
			`ARSHIFT:
				res_ <= r2 >= 0 ? r1 >>> r2 : r1 >> r2;
			`MUL:
				res_ <= r1 * r2;
			`DIV:
				res_ <= r1 / r2;
			`SUBU:
				res_ <= (r1 >= 0 ? r1 : -r1) - (r2 >= 0 ? r2 : -r2);
			`DIVU:
				res_ <= (r1 >= 0 ? r1 : -r1) / (r2 >= 0 ? r2 : -r2);
			`REMU:
				res_ <= (r1 >= 0 ? r1 : -r1) % (r2 >= 0 ? r2 : -r2);
			default:
				res_ <= res__;
		endcase

	always @(posedge clk)
		res__ <= res_;

	always @(*)
		if ((alu_op == `DIV || alu_op == `DIVU || alu_op == `REM || alu_op == `REMU) && ~(|r2))
			illegal_op <= 1;
		else
			illegal_op <= 0;

	assign zero = res_ == 0;
	assign res = res_;

endmodule
