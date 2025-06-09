module hazard_Detection_Unit(input clk,
							 input reset,
							 input EX_invalid,
							 input MEM_invalid,
							 input is_load_EX,
							 input is_load_MEM,
							 input took_branch,
							 input[4:0] rs1,
							 input[4:0] rs2,
							 input[4:0] rd,
							 output reg forward_EX_A = 0,
							 output reg forward_EX_B = 0,
							 output reg forward_MEM_A_L = 0,
							 output reg forward_MEM_B_L = 0,
							 output reg forward_MEM_A = 0,
							 output reg forward_MEM_B = 0,
							 output reg set_invalid_ID = 0,
							 output reg set_invalid_EX = 0,
							 output reg set_invalid_MEM = 0,
							 output reg set_invalid_WB = 0,
							 output reg stop_ID = 0);

	reg[4:0] ID_rs1  = 0;
	reg[4:0] ID_rs2  = 0;
	reg[4:0] ID_rd   = 0;
	reg[4:0] EX_rd   = 0;
	reg[4:0] MEM_rd  = 0;
	reg[4:0] WB_rd   = 0;

	reg rs1_nz = 0;
	reg rs2_nz = 0;

	always @(posedge clk) begin
		ID_rd <= reset ? 0 : rd;
		EX_rd <= reset ? 0 : ID_rd;
		MEM_rd <= reset ? 0 : EX_rd;
	end

	always @(*) begin
		if (reset) begin
			ID_rs1 = 0;
			ID_rs2 = 0;
			forward_EX_A = 0;
			forward_EX_B = 0;
			forward_MEM_A = 0;
			forward_MEM_B = 0;
			forward_MEM_A_L = 0;
			forward_MEM_B_L = 0;
			stop_ID = 0;
			rs1_nz = 0;
			rs2_nz = 0;
			set_invalid_EX = 0;
			set_invalid_MEM = 0;
			set_invalid_WB = 0;
			set_invalid_ID = 0;
		end
		else begin
			ID_rs1 = rs1;
			ID_rs2 = rs2;
			rs1_nz = |rs1;
			rs2_nz = |rs2;

			forward_EX_A = ~EX_invalid && rs1 == EX_rd && rs1_nz;
			forward_EX_B = ~EX_invalid && rs2 == EX_rd && rs2_nz;
			forward_MEM_A = ~MEM_invalid && ~is_load_MEM && rs1_nz && (forward_EX_A ^ (ID_rs1 == MEM_rd));
			forward_MEM_B = ~MEM_invalid && ~is_load_MEM && rs2_nz && (forward_EX_B ^ (ID_rs2 == MEM_rd));
			forward_MEM_A_L = ~MEM_invalid && is_load_MEM && rs1_nz && (forward_EX_A ^ (ID_rs1 == MEM_rd));
			forward_MEM_B_L = ~MEM_invalid && is_load_MEM && rs2_nz && (forward_EX_B ^ (ID_rs2 == MEM_rd));

			
			stop_ID = ~EX_invalid && is_load_EX && (ID_rs1 == EX_rd && rs1_nz || ID_rs2 == EX_rd && rs2_nz);

			set_invalid_WB = 0;

			if (took_branch) begin
				set_invalid_ID <= 1;
				set_invalid_EX <= 1;
				set_invalid_MEM <= 1;
			end
			else begin
				set_invalid_ID <= 0;
				set_invalid_EX <= 0;
				set_invalid_MEM <= 0;
			end
		end
	end

endmodule
