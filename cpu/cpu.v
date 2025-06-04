`include "aluops.vh"

module cpu(input clk, input[31:0] i_mem_out, output signed[31:0] d_mem_in, input signed[31:0] d_mem_out, output d_mem_wen, output[31:0] addr, output[31:0] d_addr);

	// Fetch stage
	reg[31:0] PC = 0;
	reg[31:0] MAR = 0;
	reg[31:0] MBR = 0;
	wire[31:0] new_PC;

	always @(negedge clk) begin
		PC <= new_PC;
		MAR <= PC;
	end

	assign addr = MAR;


	// Pipeline registers

	reg[31:0] IFID_PC = 0;
	wire[31:0] IFID_IR;

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
	reg IDEX_WriteUImm = 0;
	reg IDEX_PCImm = 0;
	reg IDEX_SetLessThan = 0;
	reg IDEX_Jump = 0;
	reg IDEX_NotEqual = 0;

	reg[4:0] EXMEM_RD = 0;
	reg[31:0] EXMEM_PC = 0;
	reg[31:0] EXMEM_PCIMM = 0;
	reg EXMEM_MSB = 0;
	reg EXMEM_ZERO = 0;
	reg signed[31:0] EXMEM_B = 0;
	reg signed[31:0] EXMEM_ALURES = 0;
	reg signed[31:0] EXMEM_IMM = 0;
	reg EXMEM_Branch = 0;
	reg EXMEM_LessThan = 0;
	reg EXMEM_Equal = 0;
	reg EXMEM_WriteReg = 0;
	reg EXMEM_WriteMem = 0;
	reg EXMEM_MemToReg = 0;
	reg EXMEM_PCtoReg = 0;
	reg EXMEM_WriteUImm = 0;
	reg EXMEM_PCImm = 0;
	reg EXMEM_SetLessThan = 0;
	reg EXMEM_Jump = 0;
	reg EXMEM_NotEqual = 0;

	reg[4:0] MEMWB_RD = 0;
	reg[31:0] MEMWB_PC = 0;
	reg signed[31:0] MEMWB_IMM = 0;
	reg signed[31:0] MEMWB_LOAD = 0;
	reg signed[31:0] MEMWB_ALURES = 0;
	reg MEMWB_MSB = 0;
	reg MEMWB_WriteReg = 0;
	reg MEMWB_WriteMem = 0;
	reg MEMWB_MemToReg = 0;
	reg MEMWB_PCtoReg = 0;
	reg MEMWB_WriteUImm = 0;
	reg MEMWB_SetLessThan = 0;

	assign IFID_IR = i_mem_out;

	always @(negedge clk)
		IFID_PC <= PC;

	// Decodification stage

	wire[4:0] rs1;
	wire[4:0] rs2;
	wire[4:0] rd;

	instruction_Decoder decode(.clk(clk), .instruction(IFID_IR), .rs1(rs1), .rs2(rs2), .rd(rd));

	wire Branch;
	wire AluSrc;
	wire LessThan;
	wire Equal;
	wire[4:0] AluOp;
	wire WriteReg;
	wire WriteMem;
	wire MemToReg;
	wire PCtoReg;
	wire WriteUImm;
	wire PCImm;
	wire SetLessThan;
	wire Jump;
	wire NotEqual;

	wire signed[31:0] a, b;
	wire signed[31:0] imm;
	wire signed[31:0] write_data;

	imm_Gen immgen(.instruction(IFID_IR), .imm_out(imm));
	registers regs(.clk(clk), .rs1(rs1), .rs2(rs2), .r1(a), .r2(b), .rd(MEMWB_RD), .write_data(write_data), .write_enable(MEMWB_WriteReg));
	uc control_unit(.i(IFID_IR), .Branch(Branch), .AluSrc(AluSrc), .AluOp(AluOp), .LessThan(LessThan), .Equal(Equal), .WriteReg(WriteReg), .WriteMem(WriteMem), .MemToReg(MemToReg), .PCtoReg(PCtoReg), .PCImm(PCImm), .WriteUImm(WriteUImm), .SetLessThan(SetLessThan), .Jump(Jump), .NotEqual(NotEqual));

	always @(negedge clk) begin
		IDEX_A <= a;
		IDEX_B <= b;
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
		IDEX_WriteUImm <= WriteUImm;
		IDEX_PCImm <= PCImm;
		IDEX_SetLessThan <= SetLessThan;
		IDEX_Branch <= Branch;
		IDEX_Jump <= Jump;
		IDEX_NotEqual <= NotEqual;
	end

	// Execution stage

	wire signed[31:0] alu_res;
	wire signed[31:0] alu_b = IDEX_AluSrc ? IDEX_IMM : IDEX_B;
	wire zero;

	alu alu_(.clk(clk), .alu_op(IDEX_AluOp), .r1(IDEX_A), .r2(alu_b), .res(alu_res), .zero(zero));

	always @(negedge clk) begin
		EXMEM_IMM <= IDEX_IMM;
		EXMEM_PCIMM <= IDEX_PC + (IDEX_IMM << 1);
		EXMEM_PC <= IDEX_PC;
		EXMEM_MSB <= alu_res[31];
		EXMEM_ZERO <= zero;
		EXMEM_ALURES <= alu_res;
		EXMEM_IMM <= IDEX_IMM;
		EXMEM_B <= IDEX_B;
		EXMEM_RD <= IDEX_RD;
		EXMEM_LessThan <= IDEX_LessThan;
		EXMEM_Equal <= IDEX_Equal;
		EXMEM_WriteReg <= IDEX_WriteReg;
		EXMEM_WriteMem <= IDEX_WriteMem;
		EXMEM_MemToReg <= IDEX_MemToReg;
		EXMEM_PCtoReg <= IDEX_PCtoReg;
		EXMEM_WriteUImm <= IDEX_WriteUImm;
		EXMEM_PCImm <= IDEX_PCImm;
		EXMEM_SetLessThan <= IDEX_SetLessThan;
		EXMEM_Branch <= IDEX_Branch;
		EXMEM_Jump <= IDEX_Jump;
		EXMEM_NotEqual <= IDEX_NotEqual;
	end

	// Memory stage

	wire[31:0] PC_ = EXMEM_PCImm ? EXMEM_PCIMM : EXMEM_ALURES;
	assign new_PC = (EXMEM_Jump || EXMEM_Branch && ((EXMEM_NotEqual) ? ~EXMEM_ZERO : (EXMEM_Equal) ? EXMEM_ZERO : (EXMEM_LessThan ? EXMEM_MSB : ~EXMEM_ZERO && EXMEM_MSB))) ? PC_ : PC + 32'd4;

	always @(*)
		MEMWB_LOAD <= d_mem_out;

	always @(negedge clk) begin
		MEMWB_ALURES <= EXMEM_ALURES;
		MEMWB_PC <= EXMEM_PC;
		MEMWB_IMM <= EXMEM_IMM;
		MEMWB_MSB <= EXMEM_MSB;
		MEMWB_WriteReg <= EXMEM_WriteReg;
		MEMWB_WriteMem <= EXMEM_WriteMem;
		MEMWB_MemToReg <= EXMEM_MemToReg;
		MEMWB_PCtoReg <= EXMEM_PCtoReg;
		MEMWB_WriteUImm <= EXMEM_WriteUImm;
		MEMWB_SetLessThan <= EXMEM_SetLessThan;
	end

	assign d_mem_in = EXMEM_B;
	assign d_mem_wen = EXMEM_WriteMem;
	assign d_addr = EXMEM_ALURES;
	
	// Write back stage

	assign write_data = (MEMWB_WriteUImm) ?
							MEMWB_IMM :
							(MEMWB_PCtoReg) ?
								MEMWB_PC + 4 : 
								(MEMWB_SetLessThan) ? 
									(MEMWB_MSB) ?
										'b1 :
										'b0 :
									(MEMWB_MemToReg) ?
										MEMWB_LOAD :
										MEMWB_ALURES;

endmodule

// Sign extends the immediate value
module imm_Gen(input[31:0] instruction,
			   output reg signed[31:0] imm_out);

	wire[6:0] opcode = instruction[6:0];
	wire[2:0] funct3 = instruction[14:12];
	wire[6:0] funct7 = instruction[31:25];

	always @(*)
		if (opcode == 'b0010011 || opcode == 'b0000011 || opcode == 'b1100111) begin
			// I type
			imm_out[11:0] <= instruction[31:20];
			imm_out[31:12] <= {20{instruction[31]}};
		end
		else if (opcode == 'b0100011) begin
			// S type
			imm_out[11:5] <= instruction[31:25];
			imm_out[4:0] <= instruction[11:7];
			imm_out[31:12] <= {20{instruction[31]}};
		end
		else if (opcode == 'b1100011) begin
			// B type
			imm_out[12] <= instruction[31];
			imm_out[10:5] <= instruction[30:25];
			imm_out[4:1] <= instruction[11:8];
			imm_out[11] <= instruction[7];
			imm_out[31:13] <= {19{instruction[31]}};
			imm_out[0] <= 0;
		end
		else if (opcode == 'b0110111 || opcode == 'b0010111 /* auipc */) begin
			// U type
			imm_out[31:12] <= instruction[31:12];
			imm_out[11:0] <= 0;
		end
		else if (opcode == 'b1101111) begin
			// J type
			imm_out[20] <= instruction[31];
			imm_out[10:1] <= instruction[30:21];
			imm_out[11] <= instruction[20];
			imm_out[19:12] <= instruction[19:12];
			imm_out[31:21] <= {11{instruction[31]}};
			imm_out[0] <= 0;
		end
		else
			imm_out <= 0;

endmodule

module uc(input[31:0] i,
		  output reg Branch,
		  output reg AluSrc,
		  output reg MemToReg,
		  output reg WriteMem,
		  output reg[4:0] AluOp,
		  output reg WriteReg,
		  output reg LessThan,
		  output reg Equal,
		  output reg SetLessThan,
		  output reg PCtoReg,
		  output reg WriteUImm,
		  output reg PCImm,
	      output reg Jump,
		  output reg NotEqual);

	wire[6:0] opcode = i[6:0];
	wire[2:0] funct3 = i[14:12];
	wire[6:0] funct7 = i[31:25];

	always @(*)
		if (opcode == 'b0110011) begin
			// R type
			Branch <= 0;
			Jump <= 0;
			LessThan <= 0;
			Equal <= 0;
			MemToReg <= 0;
			WriteMem <= 0;
			PCtoReg <= 0;
			WriteUImm <= 0;
			PCImm <= 0;
			WriteReg <= 1;
			AluSrc <= 0;
			NotEqual <= 0;
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
				AluOp <= `SUB;
			else
				AluOp <= `NONE;

			if (funct3 == 'h2 && funct7 == 'h0 || funct3 == 'h3 && funct7 == 0)
				SetLessThan <= 1;
			else
				SetLessThan <= 0;
		end
		else if (opcode == 'b0010011 || opcode == 'b0000011 || opcode == 'b1100111) begin
			// I type
			WriteMem <= 0;
			Branch <= 0;
			AluSrc <= 1;
			WriteUImm <= 0;
			LessThan <= 0;
			NotEqual <= 0;
			Equal <= 0;
			if (opcode == 'b0000011) begin
				// load
				MemToReg <= 1;
				Jump <= 0;
				SetLessThan <= 0;
				PCtoReg <= 0;
				AluOp <= `NONE;
				PCImm <= 0;
				WriteReg <= 1;
			end
			else if (opcode == 'b1100111) begin
				// jalr
				Jump <= 1;
				MemToReg <= 0;
				SetLessThan <= 0;
				PCtoReg <= 1;
				AluOp <= `NONE;
				PCImm <= 1;
				WriteReg <= 1;
			end
			else begin
				Jump <= 0;
				MemToReg <= 0;
				PCtoReg <= 0;
				PCImm <= 0;
				WriteReg <= 1;

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
					AluOp <= `SUB;
				else
					AluOp <= `NONE;

				if (funct3 == 'h2 || funct3 == 'h3)
					SetLessThan <= 1;
				else
					SetLessThan <= 0;
			end
		end
		else if (opcode == 'b0100011) begin
			// S type
			Branch <= 0;
			AluSrc <= 1;
			MemToReg <= 1;
			WriteMem <= 0;
			AluOp <= `ADD;
			WriteReg <= 1;
			SetLessThan <= 0;
			PCtoReg <= 0;
			WriteUImm <= 0;
			PCImm <= 0;
			Jump <= 0;
			NotEqual <= 0;
			LessThan <= 0;
			Equal <= 0;
		end
		else if (opcode == 'b1100011) begin
			// B type
			AluOp <= `NONE;
			AluSrc <= 0;
			MemToReg <= 0;
			WriteMem <= 0;
			WriteReg <= 0;
			PCtoReg <= 0;
			Branch <= 1;
			Jump <= 0;
			SetLessThan <= 0;
			WriteUImm <= 0;
			PCImm <= 1;
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
			else begin
				LessThan <= 0;
				Equal <= 0;
				NotEqual <= 0;
			end
		end
		else if (opcode == 'b0110111 || opcode == 'b0010111) begin
			// U type
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
			WriteUImm <= 0;
			MemToReg <= 0;
		end
		else if (opcode == 'b1101111) begin
			// J type
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
			WriteUImm <= 0;
			MemToReg <= 0;
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
			WriteUImm <= 0;
			MemToReg <= 0;
		end

endmodule

module instruction_Decoder(input[31:0] instruction, input clk, output reg[4:0] rs1, output reg[4:0] rs2, output reg[4:0] rd);

	wire[6:0] opcode = instruction[6:0];

	always @(posedge clk)
		if (opcode == 'b0110011) begin
			rd <= instruction[11:7];
			rs1 <= instruction[19:15];
			rs2 <= instruction[24:20];
		end
		else if (opcode == 'b0010011 || opcode == 'b0000011 || opcode == 'b1100111) begin
			rd <= instruction[11:7];
			rs1 <= instruction[19:15];
			rs2 <= 0;
		end
		else if (opcode == 'b0100011) begin
			rs1 <= instruction[19:15];
			rs2 <= instruction[24:20];
			rd <= 0;
		end
		else if (opcode == 'b1100011) begin
			rs1 <= instruction[19:15];
			rs2 <= instruction[24:20];
			rd <= 0;
		end
		else if (opcode == 'b0110111 || opcode == 'b0010111) begin
			rd <= instruction[11:7];
			rs1 <= instruction[19:15];
			rs2 <= 0;
		end
		else if (opcode == 'b1101111) begin
			rd <= instruction[11:7];
			rs1 <= instruction[19:15];
			rs2 <= 0;
		end
		else begin
			rs1 <= 0;
			rs2 <= 0;
			rd <= 0;
		end

endmodule
