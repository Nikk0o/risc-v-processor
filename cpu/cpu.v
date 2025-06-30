`include "cpu/defines.vh"

module cpu(
	input clk,
	input reset,
	input[31:0] i_mem_out,
	output signed[31:0] data_mem_in,
	input signed[31:0] data_mem_out,
	output[1:0] w_data_size,
	output data_mem_write_enable,
	output data_mem_read_enable,
	output inst_mem_read_enable,
	output[31:0] addr,
	output[31:0] d_addr,

	input minterrupt,
	input sinterrupt
	);

	reg[2:0] state = `RESET;
	reg[1:0] mode = `MACHINE;

	reg[31:0] PC = 0;
	reg[31:0] MAR = 0;
	wire[31:0] new_PC;

	reg dont_ex_fst = 1;

	assign inst_mem_read_enable = 1;

	wire stop_ID;
	wire stop_IF;

	wire any_excep;
	wire[5:0] highest_excep;
	wire deleg;

	reg EXMEM_Jalr = 0;

	/*
	* Used to delay the mode change so that it only
	* switches when the next instruction if fetched
	*/
	reg[1:0] next_mode = `MACHINE;
	always @(negedge clk)
		if (any_excep)
			next_mode <= stop_IF || stop_ID ? next_mode : deleg ? `SUPERV : `MACHINE;
		else if (EXMEM_Ret)
			next_mode <= stop_IF || stop_ID ? next_mode : mode == `MACHINE ? `SUPERV : `USER;

	always @(negedge clk or posedge reset)
		if (reset)
			mode <= `MACHINE;
		else
			mode <= next_mode;

	always @(negedge clk or posedge reset) begin
		if (reset)
			state <= `RESET;
		else if (state == `RESET)
			state <= `RUN;
		else if (state == `RUN) begin
		end
	end

	// just to avoid writing "state == `RESET" every time	
	wire reset_internal = state == `RESET;

	/*
	* Don't execute the first instruction.
	* Needed because both PC and MAR start at 0, so
	* the first 2 clock cycles fetch the same instruction, and this
	* prevents the cpu from executing the first.
	*/
	always @(negedge clk or posedge reset_internal)
		if (reset_internal)
			dont_ex_fst <= 1;
		else
			dont_ex_fst <= 0;

	always @(negedge clk) begin
		if (reset_internal) begin
			PC <= 0;
			MAR <= 0;
		end
		else begin
			PC <= EXMEM_Ret || any_excep ?
					impl_csr[63:32]
					: stop_IF ? PC
						:take_branch ?
							EXMEM_Jalr ? 
							new_PC
							: new_PC - 4
						: new_PC;

			MAR <= stop_IF ? MAR : EXMEM_Ret || any_excep ? impl_csr[63:32] - 4 : PC;
		end
	end

	assign addr = MAR;

	// Pipeline registers

	// Fetch stage
	reg IF_invalid = 0;
	reg IF_ignore = 0;
	wire IFinvalid;

	reg IF_raise_excep = 0;
	reg IF_excep_code = 0;

	// Decoding stage
	reg[31:0] IFID_PC = 0;
	reg[31:0] IFID_IR = 0;
	reg IFID_ignore = 0;
	reg IFID_invalid = 0;

	reg ID_raise_excep = 0;
	reg[3:0] ID_excep_code = 0;

	reg csr_iwrite_enable_id = 0;
	reg[31:0] csr_iwrite_data_id = 0;
	reg[11:0] csr_iaddr_id_w = 0;

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
	reg IDEX_ignore = 0;
	reg IDEX_invalid = 0;
	reg IDEX_SubAB = 0;
	reg IDEX_SubABU = 0;
	reg[3:0] IDEX_excep_code = 0;
	reg IDEX_raise_excep = 0;
	reg IDEX_Ret = 0;
	reg[31:0] IDEX_IBITS = 0;
	reg IDEX_Jalr = 0;

	reg EX_raise_excep = 0;
	reg[3:0] EX_excep_code = 0;

	reg [31:0] csr_iwrite_data_ex = 0;
	reg csr_iwrite_enable_ex = 0;
	reg[11:0] csr_iaddr_ex_w = 0;

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
	reg EXMEM_ignore = 0;
	reg EXMEM_invalid = 0;
	reg EXMEM_raise_excep = 0;
	reg[3:0] EXMEM_excep_code = 0;
	reg EXMEM_Ret = 0;
	reg[31:0] EXMEM_IBITS = 0;

	reg MEM_raise_excep = 0;
	reg[2:0] MEM_excep_code = 0;

	reg[31:0] EXMEM_csr_iwrite_data = 0;
	reg[11:0] csr_iaddr_mem_w = 0;
	reg EXMEM_csr_iwrite_enable = 0;

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
	reg MEMWB_ignore = 0;

	reg WB_raise_excep = 0;
	reg[2:0] WB_excep_code = 0;

	reg[31:0] csr_iwrite_data_wb = 0;
	reg[11:0] csr_iaddr_wb_w = 0;
	reg csr_iwrite_enable_wb = 0;

	// Forward
	wire fw_EX_A;
	wire fw_EX_B;
	wire fw_MEM_A_L, fw_MEM_A;
	wire fw_MEM_B_L, fw_MEM_B;

	always @(posedge clk)
		if (take_branch && new_PC % 4 != 0 && !stop_IF) begin
			IF_raise_excep <= 1;
			IF_excep_code <= 0;
		end
		else begin
			IF_raise_excep <= 0;
			IF_excep_code <= 0;
		end

	always @(negedge clk) begin
		IF_invalid <= reset_internal;
		IF_ignore <= IFinvalid || reset_internal;
	end

	wire IDinv = IF_invalid || reset_internal || IDinvalid || dont_ex_fst;
	always @(negedge clk) begin
		IFID_invalid <= IDinv;
		IFID_ignore <= EXMEM_Ret || IF_ignore || IDinv;

		IFID_PC <= stop_ID ? IFID_PC : PC;
		IFID_IR <= stop_ID ? IFID_IR : i_mem_out;
	end

	wire[6:0] opcode = IFID_IR[6:0];
	wire[2:0] funct3 = IFID_IR[14:12];
	wire[6:0] funct7 = IFID_IR[31:25];
	wire[11:0] funct12 = IFID_IR[31:20];

	wire[4:0] rs1 = (opcode == 'b0110111) || (opcode == 'b0010111 || opcode == 'b1101111) ? 'h0 : IFID_IR[19:15];
	wire[4:0] rs2 = IFID_IR[24:20];
	wire[4:0] rd = (opcode == 'b0100011 || opcode == 'b1100011) ? 'h0 : IFID_IR[11:7];

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
	wire SubABU;
	wire ReadCsrIDe;
	wire WriteCsrIDe;
	wire AtomicWriteReg;
	wire ReadCsrIDi;
	wire CsrSrc;
	wire[1:0] CsrOp;
	wire RaiseExcep;
	wire[3:0] ExcepCode;
	wire Ret;
	wire Jalr;

	wire signed[31:0] alu_res;
	wire signed[31:0] a, b;
	wire signed[31:0] imm;
	wire signed[31:0] write_data;

	wire[31:0] expl_csr;
	wire[127:0] impl_csr;

	wire signed[31:0] atomic_data = expl_csr;

	wire no_perm;

	wire take_branch = ~EXMEM_ignore & (EXMEM_Jump | EXMEM_Branch & (EXMEM_NotEqual ? ~EXMEM_ZERO : EXMEM_Equal ? EXMEM_ZERO : (EXMEM_LessThan ? EXMEM_MSB : ~EXMEM_MSB)));
		wire any_branch = IDEX_Branch && ~IDEX_ignore || EXMEM_Branch && ~EXMEM_ignore || IDEX_Jump && ~IDEX_ignore || EXMEM_Jump && ~EXMEM_ignore;

	imm_Gen immgen(
		.clk(clk),
		.instruction(IFID_IR),
		.opcode(opcode),
		.funct3(funct3),
		.funct7(funct7),
		.imm_out(imm)
	);

	wire wr = MEMWB_WriteReg && ~MEMWB_ignore;
	wire atomic_write_enable = AtomicWriteReg && |rd && ~IFID_ignore && ~stop_ID;

	registers regs(
		.clk(clk),
	   .reset(reset),
	   .rs1(rs1),
	   .rs2(rs2),
	   .r1(a),
	   .r2(b),
	   .atomic_rd(rd),
	   .rd(MEMWB_RD),
	   .atomic_write_data(atomic_data),
	   .write_data(write_data),
	   .write_enable(wr),
	   .atomic_write_enable(atomic_write_enable)
	);

	uc control_unit(
		.clk(clk),
		.opcode(opcode),
		.funct3(funct3),
		.funct7(funct7),
		.funct12(funct12),
		.mode(mode),
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
		.SubAB(SubAB),
		.SubABU(SubABU),
		.AtomicWriteReg(AtomicWriteReg),
		.ReadCsrIDe(ReadCsrIDe),
		.ReadCsrIDi(ReadCsrIDi),
		.WriteCsrIDe(WriteCsrIDe),
		.CsrSrc(CsrSrc),
		.CsrOp(CsrOp),
		.RaiseExcep(RaiseExcep),
		.ExcepCode(ExcepCode),
		.Ret(Ret),
		.Jalr(Jalr)
	);

	always @(*) begin
		ID_raise_excep <= IFID_ignore ? 0 : ~EXMEM_Ret & (RaiseExcep | no_perm);
		ID_excep_code <= IFID_ignore ? 0 : RaiseExcep ? ExcepCode : 'b10;
	end

	wire signed[31:0] r1 = fw_EX_A ? alu_res : fw_MEM_A ? EXMEM_ALURES : fw_MEM_A_L ? data_mem_out : a;
	wire signed[31:0] r2 = fw_EX_B ? alu_res : fw_MEM_B ? EXMEM_ALURES : fw_MEM_B_L ? data_mem_out : b;

	reg[11:0] csr_iaddr_id = 0, csr_iaddr_ex = 0, csr_iaddr_mem = 0, csr_iaddr_wb = 0;
	reg read_csr_ex = 0, read_csr_mem = 0;
	reg read_csr_wb = 0;
	reg[11:0] csr_eaddr_id = 0;

	always @(*)
		csr_eaddr_id <= IFID_IR[31:20];

	always @(*) begin
		csr_iaddr_id <= any_excep ? highest_excep >= 32 ? 'h312 : 'h302 : 'h000;
	end

	assign deleg = impl_csr[96 + highest_excep[4:0]];

	reg[31:0] csr_write_data = 0;

	always @(*)
		case(CsrOp)
			'b00:
				csr_write_data <= CsrSrc ? imm : r1;
			'b01:
				csr_write_data <= expl_csr | (CsrSrc ? imm : r1);
			'b10:
				csr_write_data <= expl_csr & ~(CsrSrc ? imm : r1);
			default:
				csr_write_data <= 0;
		endcase

	wire csr_ewrite_enable = WriteCsrIDe && |rd && ~take_branch && ~IDEX_Branch && ~IDEX_Jump && ~stop_ID;
	wire csr_eread_enable = ReadCsrIDe && |rd;
	CSRs control_status_regs(
		.clk(clk),
		.mode(mode),
		.write_enable(csr_ewrite_enable),
		.expl_addr_w(csr_eaddr_id),
		.expl_addr_r(csr_eaddr_id),
		.write_data(csr_write_data),
		.expl_read_enable(csr_eread_enable),
		.expl_csr(expl_csr),
		.impl_read_enable({ReadCsrIDi, read_csr_ex, read_csr_mem, read_csr_wb}),
		.impl_addrs_r({csr_iaddr_id, csr_iaddr_ex, csr_iaddr_mem, csr_iaddr_wb}),
		.impl_csr(impl_csr),
		.no_permission(no_perm),
		.impl_write_data({32'd0, csr_iwrite_data_ex, EXMEM_csr_iwrite_data, csr_iwrite_data_wb}),
		.impl_write_enable({1'b0, csr_iwrite_enable_ex, EXMEM_csr_iwrite_enable, csr_iwrite_enable_wb}),
		.impl_addrs_w({12'd0, csr_iaddr_ex_w, csr_iaddr_mem_w, csr_iaddr_wb_w})
	);

	// Execution stage

	wire IDEXinv = AtomicWriteReg && |rd || reset_internal || IFID_invalid || EXinvalid;
	always @(negedge clk) begin
		IDEX_invalid <= IDEXinv;
		IDEX_ignore <= EXMEM_Ret || IFID_ignore || ID_raise_excep || IDEXinv || opcode[1:0] != 2'b11;

		IDEX_A <= r1;
		IDEX_B <= r2;
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
		IDEX_SubABU <= SubABU;
		IDEX_raise_excep <= ~EXMEM_Ret && ID_raise_excep && ~IDEXinv;
		IDEX_excep_code <= ID_excep_code;
		IDEX_Ret <= ~EXMEM_Ret && Ret && ~IDEXinv;
		IDEX_IBITS <= IFID_IR;
		IDEX_Jalr <= Jalr;
	end

	always @(*) begin
		EX_raise_excep <= 0;
		EX_excep_code <= 0;

		if (any_excep) begin
			if (highest_excep == 'h0)
				csr_iwrite_data_ex <= IDEX_PC - 4;
			else if (highest_excep == 'h2)
				csr_iwrite_data_ex <= EXMEM_IBITS;
			else
				csr_iwrite_data_ex <= 0;

			csr_iwrite_enable_ex <= 1;
			csr_iaddr_ex_w <= deleg ? 'h143 : 'h343;
		end
		else begin
			csr_iaddr_ex_w <= 0;
			csr_iwrite_enable_ex <= 0;
			csr_iwrite_data_ex <= 0;
		end
	end

	wire illegal_op;

	wire signed[31:0] alu_b = IDEX_AluSrc ? IDEX_IMM : IDEX_B;
	wire[31:0] alu_a = IDEX_PCImm ? IDEX_PC : IDEX_A;
	wire zero;

	assign highest_excep =
		MEM_raise_excep ?
			MEM_excep_code == 'd0 ?
				MEM_excep_code
				: EXMEM_raise_excep ?
					EXMEM_excep_code
					: MEM_excep_code
			: EXMEM_raise_excep ?
				EXMEM_excep_code
				: 'd0;

	alu alu_(.clk(clk), .alu_op(IDEX_AluOp), .r1(alu_a), .r2(alu_b), .res(alu_res), .zero(zero), .illegal_op(illegal_op));

	wire signed[31:0] subAB = (IDEX_A >= 0 ? IDEX_A : SubABU ? -IDEX_A : IDEX_A) - (IDEX_B >= 0 ? IDEX_B : SubABU ? -IDEX_B : IDEX_B);

	// Memory stage

	wire MEMinv = reset_internal || IDEX_invalid || MEMinvalid;
	always @(negedge clk) begin
		EXMEM_invalid <= MEMinv;
		EXMEM_ignore <= EXMEM_Ret || IDEX_ignore || EX_raise_excep || MEMinv;

		EXMEM_PC <= IDEX_PC;
		EXMEM_MSB <= IDEX_SubAB ? subAB[31] : alu_res[31];
		EXMEM_ZERO <= IDEX_SubAB ? ~(|subAB) : zero;
		EXMEM_ALURES <= alu_res;
		EXMEM_OTHER <= IDEX_WriteMem ? IDEX_B : IDEX_IMM;
		EXMEM_RD <= AtomicWriteReg && IDEX_RD == rd ? 'd0 : IDEX_RD;
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
		EXMEM_raise_excep <= ~EXMEM_Ret && (IDEX_raise_excep || EX_raise_excep) && ~MEMinv;
		EXMEM_excep_code <= IDEX_raise_excep ? IDEX_excep_code : EX_excep_code;
		EXMEM_Ret <= ~EXMEM_Ret && IDEX_Ret && ~MEMinv;
		EXMEM_IBITS <= IDEX_IBITS;
		EXMEM_Jalr <= IDEX_Jalr;
	end

	assign new_PC = take_branch ? EXMEM_ALURES : PC + 4;

	reg signed[31:0] write_data_mem;
	always @(*)
		case(EXMEM_MemSize)
			`BYTE:
				write_data_mem <= {24'd0, EXMEM_OTHER[7:0]};
			`HALF:
				write_data_mem <= {16'd0,
					mode == `MACHINE && MBE || mode == `SUPERV && SBE || mode == `USER && UBE ?
						{EXMEM_OTHER[7:0], EXMEM_OTHER[15:8]}
						: mode == `MACHINE && ~MBE || mode == `SUPERV && ~SBE || mode == `USER && ~UBE ?
							EXMEM_OTHER[15:0]
							: 16'd0};
			`WORD:
				write_data_mem <=
					mode == `MACHINE && MBE || mode == `SUPERV && SBE || mode == `USER && UBE ?
						{EXMEM_OTHER[7:0], EXMEM_OTHER[15:8], EXMEM_OTHER[23:16], EXMEM_OTHER[31:24]}
						: mode == `MACHINE && ~MBE || mode == `SUPERV && ~SBE || mode == `USER && ~UBE ?
							EXMEM_OTHER
							: 32'b0;
			default:
				write_data_mem <= 'd0;
		endcase

	always @(*)
		if (~EXMEM_ignore && ((EXMEM_MemToReg || EXMEM_WriteMem) && (EXMEM_MemSize == `HALF && EXMEM_ALURES[0] != 0 || EXMEM_MemSize == `WORD && EXMEM_ALURES[1:0] != 0) || take_branch && new_PC[1:0] != 0)) begin
			MEM_raise_excep <= 1;
			MEM_excep_code <= take_branch && new_PC[1:0] != 0 ? 'd0 : EXMEM_MemToReg ? 'd4 : 'd6;
		end
		else begin
			MEM_raise_excep <= 0;
			MEM_excep_code <= 0;
		end

	assign data_mem_in = write_data_mem;
	assign data_mem_write_enable = (~MEM_raise_excep & ~EXMEM_raise_excep) & EXMEM_WriteMem & ~EXMEM_ignore;
	assign data_mem_read_enable = (~MEM_raise_excep & ~EXMEM_raise_excep) & EXMEM_MemToReg & ~EXMEM_ignore;
	assign d_addr = EXMEM_ALURES;
	assign w_data_size = EXMEM_MemSize;

	always @(*)
		read_csr_mem <= ~EXMEM_invalid && (EXMEM_WriteMem || EXMEM_MemToReg || any_excep || EXMEM_Ret);

	wire UBE = impl_csr[38];
	wire SBE = impl_csr[36];
	wire MBE = impl_csr[37];

	always @(*)
		csr_iaddr_mem <= EXMEM_Ret ? (mode == `MACHINE ? 'h341 : mode == `SUPERV ? 'h141 : 'h000) : any_excep ? 'h305 : mode == `USER ? 'h300 : 'h310;


	always @(*) begin
		csr_iaddr_mem_w <= 'h341;
		EXMEM_csr_iwrite_enable <= ~EXMEM_invalid && (any_excep);
		EXMEM_csr_iwrite_data <= ~EXMEM_invalid && (any_excep) ? EXMEM_PC + 4 : 'd0;
	end

	/*
	* The memory module must always read a word regardless of
	* the size of the data being read.
	*/
	always @(negedge clk)
		if (mode == `USER && ~UBE || mode == `SUPERV && ~SBE || mode == `MACHINE && ~MBE)
			if (EXMEM_MemSize == 1) begin
				MEMWB_LOAD[7:0] <= data_mem_out[31:24];
				MEMWB_LOAD[31:8] <= {24{!EXMEM_LoadUns && data_mem_out[31]}};
			end
			else if (EXMEM_MemSize == 2) begin
				MEMWB_LOAD[15:0] <= data_mem_out[31:16];
				MEMWB_LOAD[31:16] <= {16{!EXMEM_LoadUns && data_mem_out[31]}};
			end
			else if (EXMEM_MemSize == 3)
				MEMWB_LOAD <= data_mem_out;
			else
				MEMWB_LOAD <= 0;
		else if (mode == `USER && UBE || mode == `SUPERV && SBE || mode == `MACHINE && MBE)
			if (EXMEM_MemSize == 1) begin
				MEMWB_LOAD[7:0] <= data_mem_out[31:24];
				MEMWB_LOAD[31:8] <= {24{!EXMEM_LoadUns && data_mem_out[31]}};
			end
			else if (EXMEM_MemSize == 2) begin
				MEMWB_LOAD[15:0] <= {data_mem_out[23:16], data_mem_out[31:24]};
				MEMWB_LOAD[31:16] <= {16{!EXMEM_LoadUns && data_mem_out[23]}};
			end
			else if (EXMEM_MemSize == 3) begin
				MEMWB_LOAD <= {data_mem_out[7:0], data_mem_out[15:8], data_mem_out[23:16], data_mem_out[31:24]};
			end
			else
				MEMWB_LOAD <= 0;
		else
			MEMWB_LOAD <= 0;

	// Write back stage

	wire WBinv = reset_internal || EXMEM_invalid || WBinvalid;
	always @(negedge clk) begin
		MEMWB_invalid <= WBinv;
		MEMWB_ignore <= MEM_raise_excep || EXMEM_ignore || WBinv;

		MEMWB_ALURES <= EXMEM_ALURES;
		MEMWB_PC <= EXMEM_PC;
		MEMWB_MSB <= EXMEM_MSB;
		MEMWB_RD <= AtomicWriteReg && rd == EXMEM_RD ? 'd0 : EXMEM_RD;
		MEMWB_WriteReg <= EXMEM_WriteReg;
		MEMWB_MemToReg <= EXMEM_MemToReg;
		MEMWB_PCtoReg <= EXMEM_PCtoReg;
		MEMWB_SetLessThan <= EXMEM_SetLessThan;
	end

	always @(*) begin
		WB_raise_excep <= 0;
		WB_excep_code <= 0;

		if (any_excep) begin
			read_csr_wb <= 1;
			csr_iaddr_wb <= deleg ? 'h105 : 'h305;
		end
		else if (EXMEM_Ret) begin
			read_csr_wb <= 1;
			csr_iaddr_wb <= mode == `MACHINE ? 'h341 : mode == `SUPERV ? 'h141 : 'h000;
		end
		else begin
			read_csr_wb <= 0;
			csr_iaddr_wb <= 0;
		end
	end

	always @(*) begin
		csr_iaddr_wb_w <= any_excep ? deleg ? 'h142 : 'h342 : 'h000;
		csr_iwrite_data_wb <= highest_excep;
		csr_iwrite_enable_wb <= any_excep;
	end

	assign write_data =
		MEMWB_PCtoReg ?
			MEMWB_PC :
			MEMWB_SetLessThan ?
				{31'b0, MEMWB_MSB} :
				MEMWB_MemToReg ?
					MEMWB_LOAD :
					MEMWB_ALURES;

	wire state_reset = state == `RESET;
	wire csr_write_mstatus = WriteCsrIDe && |rd && (funct12 == 'h300 || funct12 == 'h310);

	assign any_excep = MEM_raise_excep || EXMEM_raise_excep;
	hazard_Detection_Unit haz(
		.clk(clk),
		.reset(state_reset),
		.took_branch(take_branch),
		.MEM_invalid(EXMEM_ignore),
		.EX_invalid(IDEX_ignore),
		.is_load_EX(IDEX_MemToReg),
		.is_load_MEM(EXMEM_MemToReg),
		.is_store_EX(IDEX_WriteMem),
		.csr_write_mstatus(csr_write_mstatus),
		.any_excep(any_excep),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.ret(EXMEM_Ret),
		.forward_EX_A(fw_EX_A),
		.forward_EX_B(fw_EX_B),
		.forward_MEM_A(fw_MEM_A),
		.forward_MEM_B(fw_MEM_B),
		.forward_MEM_A_L(fw_MEM_A_L),
		.forward_MEM_B_L(fw_MEM_B_L),
		.stop_ID(stop_ID),
		.stop_IF(stop_IF),
		.set_invalid_EX(EXinvalid),
		.set_invalid_ID(IDinvalid),
		.set_invalid_MEM(MEMinvalid),
		.set_invalid_WB(WBinvalid),
		.set_invalid_IF(IFinvalid),
		.csr_write(AtomicWriteReg && |rd),
		.is_branch_EX(IDEX_Jump || IDEX_Branch),
		.EX_PC(IDEX_PC),
		.ID_PC(IFID_PC)
	);

endmodule

module imm_Gen(
	input clk,
	input[6:0] opcode,
	input[2:0] funct3,
	input[6:0] funct7,
	input[31:0] instruction,
	output reg signed[31:0] imm_out);

	always @(*)
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
			'b1110011: begin
				imm_out[4:0] <= instruction[19:15];
				imm_out[31:5] <= 'd0;
			end
			default:
				imm_out <= 0;
		endcase

endmodule
