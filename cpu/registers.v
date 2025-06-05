module registers(input clk,
				 input[4:0] rs1,
				 input[4:0] rs2,
				 input[4:0] rd,
				 input write_enable,
				 input signed[31:0] write_data,
				 output reg signed[31:0] r1,
				 output reg signed[31:0] r2);

	reg signed[31:0] regs[31:0];

	// these must update on the rising edge to make data
	// avalible on the clock cycle
	always @(posedge clk) begin
		r1 = regs[rs1];
		r2 = regs[rs2];

		if (write_enable && rd != 0)
			regs[rd] <= write_data;
	end

	integer i;
	initial
		for (i = 0; i < 32; i = i + 1)
			regs[i] = 0;

endmodule
