`include "cpu/defines.vh"


module uc(
	input clk,
	input[6:0] opcode,
	input[2:0] funct3,
	input[6:0] funct7,
	input[11:0] funct12,
	input[1:0] mode,
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
	output reg PCImm,
	output reg Jump,
	output reg NotEqual,
	output reg[1:0] MemSize,
	output reg LoadUns,
	output reg SubAB,
	output reg SubABU,

	output reg AtomicWriteReg,
	output reg ReadCsrIDe,
	output reg ReadCsrIDi,
	output reg WriteCsrIDe,
	output reg CsrSrc,
	output reg[1:0] CsrOp,
	output reg RaiseExcep,
	output reg[3:0] ExcepCode,
	output reg Ret,
	output reg Jalr,
	output reg[1:0] RetFrom,
	output reg Wfi
);

	always @(*)
		// Problem: This will not raise an illegal instruction exception if an
		// instruction
		// has opcode 1110011 and doesn't match any implemented instruction.
		if (opcode == 'b1110011) begin
			if (funct3 > 0) begin
				ReadCsrIDe <= 1;
				ReadCsrIDi <= 0;
				AtomicWriteReg <= 1;
				WriteCsrIDe <= 1;
				RaiseExcep <= 0;
				ExcepCode <= 0;
				RetFrom <= 0;

				if (funct3 > 'b100)
					CsrSrc <= 1;
				else
					CsrSrc <= 0;

				if (funct3 == 'b001 || funct3 == 'b101)
					CsrOp <= 0;
				else if (funct3 == 'b010 || funct3 == 'b110)
					CsrOp <= 1;
				else if (funct3 == 'b011 || funct3 == 'b111)
					CsrOp <= 2;
				else if (funct3 == 'h0 && funct12 == 'b000100000101) begin
					CsrOp <= 0;
				end
				else
					CsrOp <= 3;

				if (funct3 == 'h0 && funct12 == 'b000100000101)
					Wfi <= 1'b1;
				else
					Wfi <= 1'b0;

				Ret <= 1'b0;
			end
			else begin
				ReadCsrIDe <= 0;
				ReadCsrIDi <= 0;
				CsrSrc <= 0;
				AtomicWriteReg <= 0;
				WriteCsrIDe <= 1;
				CsrOp <= 0;
				Wfi <= 1'b0;

				// Ecall
				if (funct12 == 0) begin
					RaiseExcep <= 1;

					if (mode == `USER)
						ExcepCode <= 'd8;
					else if (mode == `SUPERV)
						ExcepCode <= 'd9;
					else
						ExcepCode <= 'd11;

					Ret <= 1'b0;
					RetFrom <= 0;
				end
				// mret
				else if (funct12 == 'b001100000010) begin
					if (mode < `MACHINE) begin
						RaiseExcep <= 'b1;
						ExcepCode <= 'b10;
						Ret <= 1'b0;
					end
					else begin
						RaiseExcep <= 0;
						ExcepCode <= 'd0;
						Ret <= 1'b1;
					end

					RetFrom <= `MACHINE;
				end
				// uret
				else if (funct12 == 'b000000000010) begin
					RaiseExcep <= 0;
					ExcepCode <= 'd0;
					Ret <= 1'b1;

					RetFrom <= `USER;
				end
				// sret
				else if (funct12 == 'b000100000010) begin
					if (mode < `SUPERV) begin
						RaiseExcep <= 'b1;
						ExcepCode <= 'b10;
						Ret <= 1'b0;
					end
					else begin
						RaiseExcep <= 0;
						ExcepCode <= 'd0;
						Ret <= 1'b1;
					end

					RetFrom <= `SUPERV;
				end
				else begin
					RaiseExcep <= 0;
					ExcepCode <= 0;
					Ret <= 0;
					RetFrom <= 0;
				end
			end
		end
		else begin
			ReadCsrIDi <= 0;
			ReadCsrIDe <= 0;
			CsrSrc <= 0;
			AtomicWriteReg <= 0;
			WriteCsrIDe <= 0;
			Ret <= 0;
			CsrOp <= 0;
			RetFrom <= 0;
			Wfi <= 1'b0;

			if (!(opcode == 'b0110011
				|| opcode == 'b0010011
				|| opcode == 'b0000011
				|| opcode == 'b1100111
				|| opcode == 'b0100011
				|| opcode == 'b1100011
				|| opcode == 'b0110111
				|| opcode == 'b0010111
				|| opcode == 'b1101111
				|| opcode == 'b1110011)) begin
				RaiseExcep <= 1;
				ExcepCode <= 'd2;
			end
			else begin
				RaiseExcep <= 0;
				ExcepCode <= 0;
			end
		end

	always @(*)
		if (opcode == 'b1100111)
			Jalr <= 1;
		else
			Jalr <= 0;


	// S type
	always @(*)
		if (opcode == 'b0100011) begin
			WriteMem <= 1'b1;
		end
		else begin
			WriteMem <= 1'b0;
		end

	// B type
	always @(*)
		if (opcode == 'b1100011) begin
			Branch <= 1;
			SubAB <= 1;
			Equal <= funct3 == 'h0;
			NotEqual <= funct3 == 'h1;
			LessThan <= funct3 == 'h4 || funct3 == 'h6;
			SubABU <= funct3 == 'h6 || funct3 == 'h7;
		end
		else begin
			Branch <= 0;
			Equal <= 0;
			NotEqual <= 0;
			LessThan <= 0;
			SubAB <= 0;
			SubABU <= 0;
		end

	always @(*)
		if (opcode == 'b0110011) begin
			// R type
			Jump <= 0;
			MemToReg <= 0;
			PCtoReg <= 0;
			PCImm <= 0;
			WriteReg <= 1;
			AluSrc <= 0;
			MemSize <= 0;
			LoadUns <= 0;

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
		else if (opcode == 'b0010011 || opcode == 'b0000011 || opcode == 'b1100111) begin
			// I type
			AluSrc <= 1;

			if (opcode == 'b0000011) begin
				// load
				MemToReg <= 1;
				Jump <= 0;
				SetLessThan <= 0;
				PCtoReg <= 0;
				AluOp <= `ADD;
				PCImm <= 0;
				WriteReg <= 1;

				if (funct3 == 0 || funct3 == 4)
					MemSize <= 1;
				else if (funct3 == 1 || funct3 == 5)
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
			else if (opcode == 'b1100111) begin
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
		else if (opcode == 'b0100011) begin
			// S type
			AluSrc <= 1;
			MemToReg <= 0;
			AluOp <= `ADD;
			WriteReg <= 0;
			SetLessThan <= 0;
			PCtoReg <= 0;
			PCImm <= 0;
			Jump <= 0;
			LoadUns <= 0;

			if (funct3 == 'h0)
				MemSize <= 1;
			else if (funct3 == 'h1)
				MemSize <= 2;
			else if (funct3 == 'h2)
				MemSize <= 3;
			else
				MemSize <= 0;
		end
		else if (opcode == 'b1100011) begin
			// B type
			AluSrc <= 1;
			MemToReg <= 0;
			WriteReg <= 0;
			PCtoReg <= 0;
			Jump <= 0;
			SetLessThan <= 0;
			PCImm <= 1;
			LoadUns <= 0;
			MemSize <= 0;
			AluOp <= `ADD;
		end
		else if (opcode == 'b0110111 || opcode == 'b0010111) begin
			// U type
			SetLessThan <= 0;
			PCtoReg <= 0;
			WriteReg <= 1;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;

			if (opcode == 'b0110111) begin // lui
				AluOp <= `ADD;
				PCImm <= 0;
				Jump <= 0;
				AluSrc <= 1;
			end
			else begin // auipc
				AluOp <= `ADD;
				PCImm <= 1;
				Jump <= 0;
				AluSrc <= 1;
			end
		end
		else if (opcode == 'b1101111) begin
			// J type
			Jump <= 1;
			PCImm <= 1;
			AluSrc <= 1;
			AluOp <= `ADD;
			SetLessThan <= 0;
			PCtoReg <= 1;
			WriteReg <= 1;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;
		end
		else begin
			Jump <= 0;
			AluSrc <= 0;
			AluOp <= `NONE;
			PCImm <= 0;
			SetLessThan <= 0;
			PCtoReg <= 0;
			WriteReg <= 0;
			MemToReg <= 0;
			MemSize <= 0;
			LoadUns <= 0;
		end

endmodule
