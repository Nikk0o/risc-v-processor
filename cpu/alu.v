`include "aluops.vh"

module alu(
	input clk,
	input[4:0] alu_op,
	input signed[31:0] r1,
	input signed[31:0] r2,
	output signed[31:0] res,
	output zero);

	reg signed[31:0] res_ = 0;

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
			`XNOR:
				res_ <= r1 ^~ r2;
			`NOT:
				res_ <= ~r1;
			`LSHIFT:
				res_ <= r1 << r2;
			`LRSHIFT:
				res_ <= r1 >> r2;
			`ARSHIFT:
				res_ <= r1 >>> r2;
			`MUL:
				res_ <= r1 * r2;
			`DIV:
				res_ <= r1 / r2;
			default:
				res_ <= 0;
		endcase

	assign zero = res_ == 0;
	assign res = res_;

endmodule
