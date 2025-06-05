module hazard_Detection_Unit(input clk,
							 input reset,
							 input is_load_EX,
							 input[4:0] rs1,
							 input[4:0] rs2,
							 input[4:0] rd,
							 output reg forward_EX_A,
							 output reg forward_EX_B,
							 output reg forward_MEM_A,
							 output reg forward_MEM_B,
							 output reg stop_ID);

	reg[4:0] ID_rs1  = 0;
	reg[4:0] ID_rs2  = 0;
	reg[4:0] ID_rd   = 0;
	reg[4:0] EX_rd   = 0;
	reg[4:0] MEM_rd  = 0;

	always @(*) begin
		if (reset) begin
			ID_rd <= 0;
			ID_rs1 <= 0;
			ID_rs1 <= 0;
			forward_EX_A <= 0;
			forward_EX_B <= 0;
			forward_MEM_A <= 0;
			forward_MEM_B <= 0;
			stop_ID <= 0;
		end
		else begin
			ID_rd = rd;
			ID_rs1 = rs1;
			ID_rs2 = rs2;

			forward_EX_A = ID_rs1 == EX_rd && ID_rs1 != 0;
			forward_EX_B = ID_rs2 == EX_rd && ID_rs2 != 0;
			forward_MEM_A <= ID_rs1 != 0 && (forward_EX_A ^ (ID_rs1 == MEM_rd));
			forward_MEM_B <= ID_rs2 != 0 && (forward_EX_B ^ (ID_rs2 == MEM_rd));

			if (is_load_EX && (ID_rs1 == EX_rd && ID_rs1 != 0 || ID_rs2 == EX_rd && ID_rs2 != 0))
				stop_ID <= 1;
			else
				stop_ID <= 0;
		end
	end

	always @(negedge clk)
		if (reset) begin
			EX_rd <= 0;
			MEM_rd <= 0;
		end
		else begin
			EX_rd <= ID_rd;
			MEM_rd <= EX_rd;
		end

endmodule
