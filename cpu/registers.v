`include "cpu/defines.vh"

module registers(input clk,
				 input reset,
				 input[4:0] rs1,
				 input[4:0] rs2,
				 input[4:0] rd,
				 input[4:0] atomic_rd,
				 input write_enable,
				 input atomic_write_enable,
				 input signed[31:0] write_data,
				 input signed[31:0] atomic_write_data,
				 output signed[31:0] r1,
				 output signed[31:0] r2);

	reg signed[31:0] regs[31:0];
	reg[31:0] invalid_r;
	wire awen = atomic_write_enable && |atomic_rd;
	wire wen = write_enable && |rd && (rd != atomic_rd && awen || ~awen);

	always @(posedge clk)
		case ({awen, wen, reset})
			3'b010: begin
				regs[rd] <= write_data;
				invalid_r[rd] <= 0;
			end
			3'b100: begin
				regs[atomic_rd] <= atomic_write_data;
				invalid_r[atomic_rd] <= 0;
			end
			3'b110: begin
				regs[atomic_rd] <= atomic_write_data;
				regs[rd] <= write_data;

				invalid_r[atomic_rd] <= 0;
				invalid_r[rd] <= 0;
			end
			3'b000: begin
			end
			default: begin
				invalid_r <= 1;
			end
		endcase

	assign r1 = invalid_r[rs1] ? 32'd0 : regs[rs1];
	assign r2 = invalid_r[rs2] ? 32'd0 : regs[rs2];

	integer i;
	initial begin
		regs[0] = 0;
		invalid_r = {{31{1'b1}}, 1'b0};
	end

endmodule
