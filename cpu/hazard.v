module hazard_Detection_Unit(
	input clk,
	input reset,
	input go_to_next,
	input EX_invalid,
	input MEM_invalid,
	input is_load_EX,
	input is_load_MEM,
	input is_store_EX,
	input csr_write_mstatus,
	input csr_write,
	input ret,
	input took_branch,
	input is_branch_EX,
	input[31:0] ID_PC,
	input[31:0] EX_PC,
	input any_excep,
	input[4:0] rs1,
	input[4:0] rs2,
	input[4:0] rd,
	output reg forward_EX_A,
	output reg forward_EX_B,
	output reg forward_MEM_A_L,
	output reg forward_MEM_B_L,
	output reg forward_MEM_A,
	output reg forward_MEM_B,
	output reg set_invalid_IF,
	output reg set_invalid_ID,
	output reg set_invalid_EX,
	output reg set_invalid_MEM,
	output reg set_invalid_WB,
	output reg stop_IF,
	output reg stop_ID
	);

	reg[4:0] EX_rd;
	reg[4:0] MEM_rd;
	reg[4:0] WB_rd;

	reg rs1_nz;
	reg rs2_nz;

	always @(negedge clk) begin
		EX_rd <= reset ? 0 : go_to_next ? rd : EX_rd;
		MEM_rd <= reset ? 0 : go_to_next ? EX_rd : MEM_rd;
	end

	always @(posedge clk) begin
		stop_IF = ~took_branch && (
			is_branch_EX && csr_write
			|| (is_load_EX || is_store_EX) && csr_write_mstatus
			|| is_load_EX && (forward_EX_A || forward_EX_B));

		stop_ID = ~took_branch && (
			(is_load_EX || is_store_EX) && csr_write_mstatus
			|| is_load_EX && (forward_EX_A || forward_EX_B));
	end

	reg keep_invalid_ex;
	always @(negedge clk)
		keep_invalid_ex <= stop_ID;

	always @(*) begin
		if (reset) begin
			forward_EX_A = 0;
			forward_EX_B = 0;
			forward_MEM_A = 0;
			forward_MEM_B = 0;
			forward_MEM_A_L = 0;
			forward_MEM_B_L = 0;
			rs1_nz = 0;
			rs2_nz = 0;
			set_invalid_IF <= 0;
			set_invalid_EX = 0;
			set_invalid_MEM = 0;
			set_invalid_WB = 0;
			set_invalid_ID = 0;
		end
		else begin
			rs1_nz = |rs1;
			rs2_nz = |rs2;

			forward_EX_A = ~EX_invalid && rs1 == EX_rd && rs1_nz && EX_PC != ID_PC;
			forward_EX_B = ~EX_invalid && rs2 == EX_rd && rs2_nz && EX_PC != ID_PC;
			forward_MEM_A <= ~MEM_invalid && ~is_load_MEM && rs1_nz && (forward_EX_A ^ (rs1 == MEM_rd));
			forward_MEM_B <= ~MEM_invalid && ~is_load_MEM && rs2_nz && (forward_EX_B ^ (rs2 == MEM_rd));
			forward_MEM_A_L <= ~MEM_invalid && is_load_MEM && rs1_nz && (forward_EX_A ^ (rs1 == MEM_rd));
			forward_MEM_B_L <= ~MEM_invalid && is_load_MEM && rs2_nz && (forward_EX_B ^ (rs2 == MEM_rd));

			set_invalid_WB = 0;

			if (took_branch) begin
				set_invalid_IF <= 0;
				set_invalid_ID <= 1;
				set_invalid_EX <= 1;
				set_invalid_MEM <= 1;
			end
			else if (any_excep || ret) begin
				set_invalid_IF <= 0;
				set_invalid_ID <= 1;
				set_invalid_EX <= 1;
				set_invalid_MEM <= 1;
			end
			else if (stop_IF && ~stop_ID) begin
				set_invalid_IF <= 0;
				set_invalid_ID <= 1;
				set_invalid_EX <= 0;
				set_invalid_MEM <= 0;
			end
			else if (stop_ID) begin
				set_invalid_IF <= 0;
				set_invalid_ID <= 0;
				set_invalid_EX <= 1;
				set_invalid_MEM <= 0;
			end
			else begin
				set_invalid_IF <= 0;
				set_invalid_ID <= 0;
				set_invalid_EX <= 0;
				set_invalid_MEM <= 0;
			end
		end
	end

endmodule
