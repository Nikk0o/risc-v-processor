module registers(input clk,
				 input reset,
				 input[4:0] rs1,
				 input[4:0] rs2,
				 input[4:0] rd,
				 input write_enable,
				 input signed[31:0] write_data,
				 output signed[31:0] r1,
				 output signed[31:0] r2);

	reg signed[31:0] regs[31:0];
	reg[31:0] invalid_r = 0;
	wire wen = write_enable && |rd;
	reg[4:0] rd_internal = 0;

	// these must update on the rising edge to make data
	// avalible on the clock cycle
	integer j;
	always @(posedge clk) begin
		if (reset) begin
			rd_internal <= 0;
			invalid_r <= {{31{1'b1}}, 1'b0};
		end
		else begin
			rd_internal <= rd;

			if (wen) begin
				regs[rd] <= write_data;
				if (invalid_r[rd])
					invalid_r[rd] <= 0;
			end
		end
	end

	assign r1 = rd_internal == rd && |rd ? write_data : invalid_r[rs1] ? 32'd0 : regs[rs1];
	assign r2 = rd_internal == rd && |rd ? write_data : invalid_r[rs2] ? 32'd0 : regs[rs2];

	integer i;
	initial
		for (i = 0; i < 32; i = i + 1)
			regs[i] = 0;

endmodule
