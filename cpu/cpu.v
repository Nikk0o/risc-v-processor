`include "cpu/aluops.vh"

module cpu(input clk,
		   input reset,
		   input[31:0] i_mem_out,
		   output signed[31:0] data_mem_in,
		   output[1:0] rw_data_size,
		   input signed[31:0] data_mem_out,
		   output data_mem_write_enable,
		   output data_mem_read_enable,
		   output inst_mem_read_enable,
		   output[31:0] addr,
		   output[31:0] d_addr);

	// In this CPU, PC points to two instructions ahead instead of one
	// and cPC points to the next instruction. I did this because of a
	// simulation error that made the PC initialize as 4 instead of 0
	reg[31:0] PC = 0;
	reg[31:0] MAR = 0;
	wire[31:0] new_PC;
	reg[31:0] cPC = 0;

	assign inst_mem_read_enable = 1;

	always @(negedge clk) begin
		if (reset) begin
			PC <= 0;
			cPC <= 0;
			MAR <= 0;
		end
		else begin
			PC <= stop_ID ? PC : take_branch ? new_PC + 4 : new_PC;
			cPC <= stop_ID ? cPC : take_branch ? new_PC : PC;
			MAR <= stop_ID ? MAR : take_branch ? new_PC : PC;
		end
	end

	assign addr = MAR;


	// Pipeline registers

	// Decoding stage
	reg[31:0] IFID_PC = 0;
	reg[31:0] IFID_IR = 0;
	reg IFID_invalid = 0;

	// Execution stage
	reg signed[31:0] IDEX_A = 0;
	reg signed[31:0] IDEX_B = 0;
	reg[4:0] IDEX_RD = 0;
	reg signed[31:0] IDEX_IMM = 0;
	reg[31:0] IDEX_PC = 0;
	reg IDEX_Branch = 0;
	reg IDEX_AluSrc = 0;
	reg IDEX_LessThan = 0;
	reg IDEX_Equal = 0;
	reg[4:0] IDEX_AluOp = 0;
	reg IDEX_WriteReg = 0;
	reg IDEX_WriteMem = 0;
	reg IDEX_MemToReg = 0;
	reg IDEX_PCtoReg = 0;
	reg IDEX_PCImm = 0;
	reg IDEX_SetLessThan = 0;
	reg IDEX_Jump = 0;
	reg IDEX_NotEqual = 0;
	reg[1:0] IDEX_MemSize = 0;
	reg IDEX_LoadUns = 0;
	reg IDEX_invalid = 0;
	reg IDEX_SubAB = 0;

	// Memory access stage
	reg[4:0] EXMEM_RD = 0;
	reg[31:0] EXMEM_PC = 0;
	reg EXMEM_MSB = 0;
	reg EXMEM_ZERO = 0;
	reg signed[31:0] EXMEM_OTHER = 0;
	reg signed[31:0] EXMEM_ALURES = 0;
	reg EXMEM_Branch = 0;
	reg EXMEM_LessThan = 0;
	reg EXMEM_Equal = 0;
	reg EXMEM_WriteReg = 0;
	reg EXMEM_WriteMem = 0;
	reg EXMEM_MemToReg = 0;
	reg EXMEM_PCtoReg = 0;
	reg EXMEM_SetLessThan = 0;
	reg EXMEM_Jump = 0;
	reg EXMEM_NotEqual = 0;
	reg[1:0] EXMEM_MemSize = 0;
	reg EXMEM_LoadUns = 0;
	reg EXMEM_invalid = 0;

	// Write back stage
	reg[4:0] MEMWB_RD = 0;
	reg[31:0] MEMWB_PC = 0;
	reg signed[31:0] MEMWB_LOAD = 0;
	reg signed[31:0] MEMWB_ALURES = 0;
	reg MEMWB_MSB = 0;
	reg MEMWB_WriteReg = 0;
	reg MEMWB_MemToReg = 0;
	reg MEMWB_PCtoReg = 0;
	reg MEMWB_SetLessThan = 0;
	reg MEMWB_invalid = 0;

	wire fw_EX_A;
	wire fw_EX_B;
	wire fw_MEM_A_L, fw_MEM_A;
	wire fw_MEM_B_L, fw_MEM_B;
	wire stop_ID;

	always @(negedge clk) begin
		IFID_invalid <= reset | IDinvalid;

		IFID_PC <= stop_ID ? IFID_PC : cPC;
		IFID_IR <= stop_ID ? IFID_IR : i_mem_out;
	end

	wire[6:0] opcode = IFID_IR[6:0];
	wire[2:0] funct3 = IFID_IR[14:12];
	wire[6:0] funct7 = IFID_IR[31:25];

	wire[4:0] rs1 = |(opcode[6:2] - 'b01101) | |(opcode[6:2] - 'b00101) ? 0 : IFID_IR[19:15];
	wire[4:0] rs2 = IFID_IR[24:20];
	wire[4:0] rd = IFID_IR[11:7];

	// Control unit signals
	wire Branch;
	wire AluSrc;
	wire LessThan;
	wire Equal;
	wire[4:0] AluOp;
	wire WriteReg;
	wire WriteMem;
	wire MemToReg;
	wire PCtoReg;
	wire PCImm;
	wire SetLessThan;
	wire Jump;
	wire NotEqual;
	wire[1:0] MemSize;
	wire LoadUns;
	wire WritePCImm;
	wire IDinvalid;
	wire EXinvalid;
	wire MEMinvalid;
	wire WBinvalid;
	wire SubAB;

	wire signed[31:0] alu_res;
	wire signed[31:0] a, b;
	wire signed[31:0] imm;
	wire signed[31:0] write_data;

	wire take_branch = ~stop_ID & ~EXMEM_invalid & (EXMEM_Jump | EXMEM_Branch & (EXMEM_NotEqual ? ~EXMEM_ZERO : EXMEM_Equal ? EXMEM_ZERO : (EXMEM_LessThan ? EXMEM_MSB : ~EXMEM_ZERO & ~EXMEM_MSB)));

	imm_Gen immgen(.clk(clk),
				   .instruction(IFID_IR),
				   .opcode(opcode),
				   .funct3(funct3),
				   .funct7(funct7),
				   .imm_out(imm));

	wire wr = MEMWB_WriteReg & ~MEMWB_invalid;

	registers regs(.clk(clk),
				   .reset(reset),
				   .rs1(rs1),
				   .rs2(rs2),
				   .r1(a),
				   .r2(b),
				   .rd(MEMWB_RD),
				   .write_data(write_data),
				   .write_enable(wr));

	uc control_unit(.clk(clk),
					.opcode(opcode[6:2]),
					.funct3(funct3),
					.funct7(funct7),
					.Branch(Branch),
					.AluSrc(AluSrc),
					.AluOp(AluOp),
					.LessThan(LessThan),
					.Equal(Equal),
					.WriteReg(WriteReg),
					.WriteMem(WriteMem),
					.MemToReg(MemToReg),
					.PCtoReg(PCtoReg),
					.PCImm(PCImm),
					.SetLessThan(SetLessThan),
					.Jump(Jump),
					.NotEqual(NotEqual),
					.MemSize(MemSize),
					.LoadUns(LoadUns),
					.SubAB(SubAB));

	always @(negedge clk) begin
		IDEX_invalid <= IFID_invalid | EXinvalid | opcode[1:0] != 2'b11;

		if (!stop_ID) begin
			IDEX_A <= fw_EX_A ? alu_res : fw_MEM_A ? EXMEM_ALURES : fw_MEM_A_L ? data_mem_out : a;
			IDEX_B <= fw_EX_B ? alu_res : fw_MEM_B ? EXMEM_ALURES : fw_MEM_B_L ? data_mem_out : b;
			IDEX_RD <= rd;
			IDEX_IMM <= imm;
			IDEX_PC <= IFID_PC;
			IDEX_AluSrc <= AluSrc;
			IDEX_LessThan <= LessThan;
			IDEX_Equal <= Equal;
			IDEX_AluOp <= AluOp;
			IDEX_WriteReg <= WriteReg;
			IDEX_WriteMem <= WriteMem;
			IDEX_MemToReg <= MemToReg;
			IDEX_PCtoReg <= PCtoReg;
			IDEX_PCImm <= PCImm;
			IDEX_SetLessThan <= SetLessThan;
			IDEX_Branch <= Branch;
			IDEX_Jump <= Jump;
			IDEX_NotEqual <= NotEqual;
			IDEX_MemSize <= MemSize;
			IDEX_LoadUns <= LoadUns;
			IDEX_SubAB <= SubAB;
		end
	end

	wire signed[31:0] alu_b = IDEX_AluSrc ? IDEX_IMM : IDEX_B;
	wire[31:0] alu_a = IDEX_PCImm ? IDEX_PC : IDEX_A;
	wire zero;

	alu alu_(.clk(clk), .alu_op(IDEX_AluOp), .r1(alu_a), .r2(alu_b), .res(alu_res), .zero(zero));

	wire signed[31:0] subAB = IDEX_A - IDEX_B;

	always @(negedge clk) begin
		EXMEM_invalid <= IDEX_invalid | MEMinvalid;

		EXMEM_PC <= IDEX_PC;
		EXMEM_MSB <= IDEX_SubAB ? subAB[31] : alu_res[31];
		EXMEM_ZERO <= IDEX_SubAB ? ~(|subAB) : zero;
		EXMEM_ALURES <= alu_res;
		EXMEM_OTHER <= IDEX_WriteMem ? IDEX_B : IDEX_IMM;
		EXMEM_RD <= IDEX_RD;
		EXMEM_LessThan <= IDEX_LessThan;
		EXMEM_Equal <= IDEX_Equal;
		EXMEM_WriteReg <= IDEX_WriteReg;
		EXMEM_WriteMem <= IDEX_WriteMem;
		EXMEM_MemToReg <= IDEX_MemToReg;
		EXMEM_PCtoReg <= IDEX_PCtoReg;
		EXMEM_SetLessThan <= IDEX_SetLessThan;
		EXMEM_Branch <= IDEX_Branch;
		EXMEM_Jump <= IDEX_Jump;
		EXMEM_NotEqual <= IDEX_NotEqual;
		EXMEM_MemSize <= IDEX_MemSize;
		EXMEM_LoadUns <= IDEX_LoadUns;
	end

	// Memory stage
	assign new_PC = take_branch ? EXMEM_ALURES : PC + 4;

	assign data_mem_in = EXMEM_OTHER;
	assign data_mem_write_enable = EXMEM_WriteMem & ~EXMEM_invalid;
	assign data_mem_read_enable = EXMEM_MemToReg & ~EXMEM_invalid;
	assign d_addr = EXMEM_ALURES;
	assign rw_data_size = EXMEM_MemSize;

	always @(negedge clk)
		if (EXMEM_MemSize == 1) begin
			MEMWB_LOAD[7:0] <= data_mem_out[7:0];
			MEMWB_LOAD[31:8] <= {24{EXMEM_LoadUns ^ data_mem_out[31]}};
		end
		else if (EXMEM_MemSize == 2) begin
			MEMWB_LOAD[15:0] <= data_mem_out[15:0];
			MEMWB_LOAD[31:16] <= {16{EXMEM_LoadUns ^ data_mem_out[31]}};
		end
		else if (EXMEM_MemSize == 3)
			MEMWB_LOAD <= data_mem_out;
		else
			MEMWB_LOAD <= 'h0;

	always @(negedge clk) begin
		MEMWB_invalid <= EXMEM_invalid | WBinvalid;

		MEMWB_ALURES <= EXMEM_ALURES;
		MEMWB_PC <= EXMEM_PC;
		MEMWB_MSB <= EXMEM_MSB;
		MEMWB_RD <= EXMEM_RD;
		MEMWB_WriteReg <= EXMEM_WriteReg;
		MEMWB_MemToReg <= EXMEM_MemToReg;
		MEMWB_PCtoReg <= EXMEM_PCtoReg;
		MEMWB_SetLessThan <= EXMEM_SetLessThan;
	end
	
	// Write back stage
	assign write_data = (MEMWB_PCtoReg) ?
							MEMWB_PC + 32'd4 :
							(MEMWB_SetLessThan) ?
								{30'b0, MEMWB_MSB} :
								(MEMWB_MemToReg) ?
									MEMWB_LOAD :
									MEMWB_ALURES;

	hazard_Detection_Unit haz(
					.clk(clk),
					.reset(reset),
					.took_branch(take_branch),
					.MEM_invalid(EXMEM_invalid),
					.EX_invalid(IDEX_invalid),
					.is_load_EX(IDEX_MemToReg),
					.is_load_MEM(EXMEM_MemToReg),
					.rs1(rs1),
					.rs2(rs2),
					.rd(rd),
					.forward_EX_A(fw_EX_A),
					.forward_EX_B(fw_EX_B),
					.forward_MEM_A(fw_MEM_A),
					.forward_MEM_B(fw_MEM_B),
					.forward_MEM_A_L(fw_MEM_A_L),
					.forward_MEM_B_L(fw_MEM_B_L),
					.stop_ID(stop_ID),
					.set_invalid_EX(EXinvalid),
					.set_invalid_ID(IDinvalid),
					.set_invalid_MEM(MEMinvalid),
					.set_invalid_WB(WBinvalid));

endmodule

module imm_Gen(input clk,
			   input[6:0] opcode,
			   input[2:0] funct3,
			   input[6:0] funct7,
			   input[31:0] instruction,
			   output reg signed[31:0] imm_out);

	always @(posedge clk)
		case (opcode)
			'b0010011: begin
				imm_out[11:0] <= instruction[31:20];
				imm_out[31:12] <= {20{instruction[31]}};
			end
			'b0000011: begin
				imm_out[11:0] <= instruction[31:20];
				imm_out[31:12] <= {20{instruction[31]}};
			end
			'b1100111: begin
				imm_out[11:0] <= instruction[31:20];
				imm_out[31:12] <= {20{instruction[31]}};
			end
			'b0100011: begin
				imm_out[11:5] <= instruction[31:25];
				imm_out[4:0] <= instruction[11:7];
				imm_out[31:12] <= {20{instruction[31]}};
			end
			'b1100011: begin
				imm_out[12] <= instruction[31];
				imm_out[10:5] <= instruction[30:25];
				imm_out[4:1] <= instruction[11:8];
				imm_out[11] <= instruction[7];
				imm_out[31:13] <= {19{instruction[31]}};
				imm_out[0] <= 0;
			end
			'b0110111: begin
				imm_out[31:12] <= instruction[31:12];
				imm_out[11:0] <= 0;
			end
			'b0010111: begin
				imm_out[31:12] <= instruction[31:12];
				imm_out[11:0] <= 0;
			end
			'b1101111: begin
				imm_out[20] <= instruction[31];
				imm_out[10:1] <= instruction[30:21];
				imm_out[11] <= instruction[20];
				imm_out[19:12] <= instruction[19:12];
				imm_out[31:21] <= {11{instruction[31]}};
				imm_out[0] <= 0;
			end
			default:
				imm_out <= 0;
		endcase

endmodule

module uc(input clk,
		  input[4:0] opcode,
		  input[2:0] funct3,
		  input[6:0] funct7,
		  output reg Branch = 0,
		  output reg AluSrc = 0,
		  output reg MemToReg = 0,
		  output reg WriteMem = 0,
		  output reg[4:0] AluOp = 0,
		  output reg WriteReg = 0,
		  output reg LessThan = 0,
		  output reg Equal = 0,
		  output reg SetLessThan = 0,
		  output reg PCtoReg = 0,
		  output reg PCImm = 0,
	      output reg Jump = 0,
		  output reg NotEqual = 0,
	      output reg[1:0] MemSize = 0,
		  output reg LoadUns = 0,
		  output reg SubAB = 0);

	always @(*)
		if (opcode == 'b01100) begin
			// R type
			Branch <= 0;
			Jump <= 0;
			LessThan <= 0;
			Equal <= 0;
			MemToReg <= 0;
			WriteMem <= 0;
			PCtoReg <= 0;
			PCImm <= 0;
			WriteReg <= 1;
			AluSrc <= 0;
			NotEqual <= 0;
			MemSize <= 0;
			LoadUns <= 0;
			SubAB = 0;

			if (funct3 == 0 && funct7 == 0)
				AluOp <= `ADD;
			else if (funct3 == 0 && funct7 == 'h20)
				AluOp <= `SUB;
			else if (funct3 == 'h4 && funct7 == 0)
				AluOp <= `XOR;
			else if (funct3 == 'h6 && funct7 == 0)
				AluOp <= `OR;
			else if (funct3 == 'h7 && funct7 == 0)
				AluOp <= `AND;
			else if (funct3 == 'h1 && funct7 == 0)
				AluOp <= `LSHIFT;
			else if (funct3 == 'h5 && funct7 == 'h0)
				AluOp <= `LRSHIFT;
			else if (funct3 == 'h5 && funct7 == 'h20)
				AluOp <= `ARSHIFT;
			else if (funct3 == 'h2 && funct7 == 'h0)
				AluOp <= `SUB;
			else if (funct3 == 'h3 && funct7 == 0)
				AluOp <= `SUBU;
			`ifdef RV32M
			else if (funct3 == 'b101 && funct7 == 'h0)
				AluOp <= `DIVU;
			else if (funct3 == 'h7 && funct7 <= 'h1)
				AluOp <= `REMU;
			else if (funct3 == 'h6 && funct7 == 'h1)
				AluOp <= `REM;
			else if (funct3 == 'h0 && funct7 == 'h1)
				AluOp <= `MUL;
			`endif
			else
				AluOp <= `NONE;

			if (funct3 == 'h2 && funct7 == 'h0 || funct3 == 'h3 && funct7 == 0)
				SetLessThan <= 1;
			else
				SetLessThan <= 0;
		end
		else if (opcode == 'b00100 || opcode == 'b00000 || opcode == 'b11001) begin
			// I type
			WriteMem <= 0;
			Branch <= 0;
			AluSrc <= 1;
			LessThan <= 0;
			NotEqual <= 0;
			Equal <= 0;
			SubAB = 0;

			if (opcode == 'b00000) begin
				// load
				MemToReg <= 1;
				Jump <= 0;
				SetLessThan <= 0;
				PCtoReg <= 0;
				AluOp <= `ADD;
				PCImm <= 0;
				WriteReg <= 1;

				if (funct3 == 0)
					MemSize <= 1;
				else if (funct3 == 1)
					MemSize <= 2;
				else if (funct3 == 2)
					MemSize <= 3;
				else
					MemSize <= 0;

				if (funct3 == 4 || funct3 == 5)
					LoadUns <= 1;
				else
					LoadUns <= 0;
			end
			else if (opcode == 'b11001) begin
				// jalr
				Jump <= 1;
				MemToReg <= 0;
				SetLessThan <= 0;
				PCtoReg <= 1;
				AluOp <= `ADD;
				PCImm <= 0;
				WriteReg <= 1;
				LoadUns <= 0;
				MemSize <= 0;
			end
			else begin
				Jump <= 0;
				MemToReg <= 0;
				PCtoReg <= 0;
				PCImm <= 0;
				WriteReg <= 1;
				MemSize <= 0;
				LoadUns <= 0;

				// Arithmetic operations
				if (funct3 == 'h0)
					AluOp <= `ADD;
				else if (funct3 == 'h4)
					AluOp <= `XOR;
				else if (funct3 == 'h6)
					AluOp <= `OR;
				else if (funct3 == 'h7)
					AluOp <= `AND;
				else if (funct3 == 'h1 && funct7 == 0)
					AluOp <= `LSHIFT;
				else if (funct3 == 'h5 && funct7 == 0)
					AluOp <= `LRSHIFT;
				else if (funct3 == 'h5 && funct7 == 'h20)
					AluOp <= `ARSHIFT;
				else if (funct3 == 'h2)
					AluOp <= `SUB;
				else if (funct3 == 'h3)
					AluOp <= `SUBU;
				else
					AluOp <= `NONE;

				if (funct3 == 'h2 || funct3 == 'h3)
					SetLessThan <= 1;
				else
					SetLessThan <= 0;
			end
		end
		else if (opcode == 'b01000) begin
			// S type
			Branch <= 0;
			AluSrc <= 1;
			MemToReg <= 0;
			WriteMem <= 1;
			AluOp <= `ADD;
			WriteReg <= 0;
			SetLessThan <= 0;
			PCtoReg <= 0;
			PCImm <= 0;
			Jump <= 0;
			NotEqual <= 0;
			LessThan <= 0;
			Equal <= 0;
			LoadUns <= 0;
			SubAB = 0;

			if (funct3 == 'h0)
				MemSize <= 1;
			else if (funct3 == 'h1)
				MemSize <= 2;
			else if (funct3 == 'h2)
				MemSize <= 3;
			else
				MemSize <= 0;
		end
		else if (opcode == 'b11000) begin
			// B type
			AluSrc <= 0;
			MemToReg <= 0;
			WriteMem <= 0;
			WriteReg <= 0;
			PCtoReg <= 0;
			Branch <= 1;
			Jump <= 0;
			SetLessThan <= 0;
			PCImm <= 1;
			LoadUns <= 0;
			SubAB <= 1;
			MemSize <= 0;

			if (funct3 == 'h6 || funct3 == 'h7)
				AluOp <= `SUBU;
			else
				AluOp <= `SUB;

			if (funct3 == 0) begin
				// eq
				Equal <= 1;
				LessThan <= 0;
				NotEqual <= 0;
			end
			else if (funct3 == 'h1) begin
				// ne
				Equal <= 0;
				LessThan <= 0;
				NotEqual <= 1;
			end
			else if (funct3 == 'h4) begin
				// lt
				LessThan <= 1;
				Equal <= 0;
				NotEqual <= 0;
			end
			else if (funct3 == 'h5) begin
				// ge
				LessThan <= 0;
				Equal <= 0;
				NotEqual <= 0;
			end
			else if (funct3 == 'h6) begin
				// ltu
				LessThan <= 1;
				Equal <= 0;
				NotEqual <= 0;
			end
			else if (funct3 == 'h7) begin
				// geu
				LessThan <= 0;
				Equal <= 0;
				NotEqual <= 0;
			end
			else begin
				LessThan <= 0;
				Equal <= 0;
				NotEqual <= 0;
			end
		end
		else if (opcode == 'b01101 || opcode == 'b00101) begin
			// U type
			Branch <= 0;
			LessThan <= 0;
			Equal <= 0;
			NotEqual <= 0;
			SetLessThan <= 0;
			PCtoReg <= 0;
			WriteReg <= 1;
			WriteMem <= 0;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;
			SubAB = 0;

			if (opcode == 'b01101) begin // lui
				AluOp <= `ADD;
				PCImm <= 0;
				Jump <= 0;
				AluSrc <= 1;
			end
			else begin // auipc
				AluOp <= `ADD;
				PCImm <= 1;
				Jump <= 1;
				AluSrc <= 1;
			end
		end
		else if (opcode == 'b11011) begin
			// J type
			Branch <= 0;
			Jump <= 1;
			LessThan <= 0;
			Equal <= 0;
			NotEqual <= 0;
			PCImm <= 1;
			AluSrc <= 0;
			AluOp <= `ADD;
			SetLessThan <= 0;
			PCtoReg <= 1;
			WriteReg <= 1;
			WriteMem <= 0;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;
			SubAB = 0;
		end
		else begin
			Branch <= 0;
			Jump <= 0;
			LessThan <= 0;
			Equal <= 0;
			NotEqual <= 0;
			AluSrc <= 0;
			AluOp <= `NONE;
			PCImm <= 0;
			SetLessThan <= 0;
			PCtoReg <= 0;
			WriteReg <= 0;
			WriteMem <= 0;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;
			SubAB = 0;
		end

endmodule
