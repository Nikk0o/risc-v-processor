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
	reg[31:0] invalid_r = 0;
	wire wen = write_enable && |rd || atomic_write_enable && |atomic_rd;

	always @(posedge clk) begin
		if (reset) begin
			invalid_r <= {{31{1'b1}}, 1'b0};
		end
		else begin
			if (wen)
				if (atomic_write_enable && |atomic_rd) begin
					if (write_enable && |rd) begin
						if (rd == atomic_rd)
							regs[atomic_rd] <= atomic_write_data;
						else begin
							regs[atomic_rd] <= atomic_write_data;
							regs[rd] <= write_data;

							invalid_r[rd] <= 0;
						end
					end
					else
						regs[atomic_rd] <= atomic_write_data;

					invalid_r[atomic_rd] <= 0;
				end
				else begin
					regs[rd] <= write_data;
					invalid_r[rd] <= 0;
				end
		end
	end

	assign r1 = rs1 == atomic_rd && |atomic_rd && atomic_write_enable ? atomic_write_data : rs1 == rd && |rd && write_enable ? write_data : invalid_r[rs1] ? 32'd0 : regs[rs1];
	assign r2 = rs2 == atomic_rd && |atomic_rd && atomic_write_enable ? atomic_write_data : rs2 == rd && |rd && write_enable ? write_data : invalid_r[rs2] ? 32'd0 : regs[rs2];

	integer i;
	initial
		for (i = 0; i < 32; i = i + 1)
			regs[i] = 0;

endmodule
