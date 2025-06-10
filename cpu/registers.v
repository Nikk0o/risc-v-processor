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
	wire wen = write_enable && |rd;
	reg[4:0] rd_internal = 0;

	// these must update on the rising edge to make data
	// avalible on the clock cycle
	integer j;
	always @(posedge clk) begin
		if (reset) begin
			rd_internal <= 0;

			for (j = 0; j < 32; j = j + 1)
				regs[j] <= 0;
		end
		else begin
			rd_internal <= rd;

			if (wen)
				regs[rd] <= write_data;
		end
	end

	assign r1 = regs[rs1];
	assign r2 = regs[rs2];

	integer i;
	initial
		for (i = 0; i < 32; i = i + 1)
			regs[i] = 0;

endmodule
