`include "cpu/defines.vh"

module cpu(
	input clk,
	input reset,
	input enable_,

	input[31:0] mem_out,
	output reg[31:0] mem_in,

	output[1:0] data_size,
	output mem_write_enable,
	output mem_read_enable,
	output[31:0] addr,
	input mem_ready,

	input interrupt_m,
	input interrupt_type_m,

	input interrupt_s,
	input interrupt_type_s
);

	parameter starting_point = 0;

	/* Stage and mem_byte are used for loading and storing memory, as well
	 * as reading instructions.
	 *
	 * stage tells if the it is instruction (1) or data (0)
	 */
	reg stage;

	reg[2:0] state;
	reg[1:0] mode = `MACHINE;

	reg[31:0] PC = starting_point;
	reg[31:0] MAR = starting_point;
	wire[31:0] new_PC;

	reg dont_ex_fst = 1;

	wire stop_ID;
	wire stop_IF;

	wire any_excep;
	reg[5:0] highest_excep;
	wire deleg;

	reg EXMEM_Jalr;

	reg[1:0] xPP;

	/*
	* Used to delay the mode change so that it only
	* switches when the next instruction if fetched
	*/
	reg[1:0] next_mode = `MACHINE;
	always @(negedge clk)
		if (!enable_)
			if (any_excep && stage == 0 && mem_ready)
				next_mode <= stop_IF ? next_mode : deleg && mode != `MACHINE ? `SUPERV : `MACHINE;
			else if (EXMEM_Ret && EXMEM_RetFrom == mode && stage == 1 && mem_ready)
				next_mode <= stop_IF ? next_mode : xPP;

	always @(negedge stage or posedge reset)
		if (reset)
			mode <= `MACHINE;
		else
			mode <= next_mode;

	always @(negedge stage or posedge reset) begin
		if (reset)
			state <= `RESET;
		else if (state == `RESET && !enable_)
			state <= `RUN;
	end

	// just to avoid writing "state == `RESET" every time	
	wire reset_internal = state == `RESET;

	/*
	* Don't execute the first instruction.
	* Needed because both PC and MAR start at 0, so
	* the first 2 clock cycles fetch the same instruction, and this
	* prevents the cpu from executing the first.
	*/
	always @(posedge clk or posedge reset_internal)
		if (reset_internal)
			dont_ex_fst <= 1;
		else if (stage == 1 && !enable_)
			dont_ex_fst <= 0;

	always @(posedge stage) begin
		if (!enable_)
			if (reset_internal) begin
				PC <= starting_point;
				MAR <= starting_point;
				minstret <= 0;
			end
			else begin
				PC <= EXMEM_Ret && mode == EXMEM_RetFrom ?
						(mode == `MACHINE ? mepc : sepc)
						: any_excep ?
							(deleg && mode < `MACHINE ? stvec : mtvec)
							: stop_IF || Wfi ?
								PC
								: new_PC;

				MAR <= stop_IF || Wfi ? MAR : PC;
			end
	end

	always @(negedge clk)
		if (!enable_)
			if (reset)
				stage <= 0;
			else if ((mem_read_enable | mem_write_enable) & mem_ready || !(mem_read_enable | mem_write_enable))
				stage <= ~stage;

	// Pipeline registers

	// Fetch stage
	reg IF_invalid;
	reg IF_ignore;
	wire IFinvalid;

	reg IF_raise_excep;
	reg IF_excep_code;

	// Decoding stage
	reg[31:0] IFID_PC;
	reg[31:0] IFID_IR;
	reg IFID_ignore;
	reg IFID_invalid;

	reg ID_raise_excep;
	reg[3:0] ID_excep_code;

	// Execution stage
	reg signed[31:0] IDEX_A;
	reg signed[31:0] IDEX_B;
	reg[4:0] IDEX_RD;
	reg signed[31:0] IDEX_IMM;
	reg[31:0] IDEX_PC;
	reg IDEX_Branch;
	reg IDEX_AluSrc;
	reg IDEX_LessThan;
	reg IDEX_Equal;
	reg[4:0] IDEX_AluOp;
	reg IDEX_WriteReg;
	reg IDEX_WriteMem;
	reg IDEX_MemToReg;
	reg IDEX_PCtoReg;
	reg IDEX_PCImm;
	reg IDEX_SetLessThan;
	reg IDEX_Jump;
	reg IDEX_NotEqual;
	reg[1:0] IDEX_MemSize;
	reg IDEX_LoadUns;
	reg IDEX_ignore;
	reg IDEX_invalid;
	reg IDEX_SubAB;
	reg IDEX_SubABU;
	reg[3:0] IDEX_excep_code;
	reg IDEX_raise_excep;
	reg IDEX_Ret;
	reg[31:0] IDEX_IBITS;
	reg IDEX_Jalr;
	reg[1:0] IDEX_RetFrom;
	reg IDEX_Wfi;

	reg EX_raise_excep;
	reg[3:0] EX_excep_code;

	// Memory access stage
	reg[4:0] EXMEM_RD;
	reg[31:0] EXMEM_PC;
	reg EXMEM_MSB;
	reg EXMEM_ZERO;
	reg signed[31:0] EXMEM_OTHER;
	reg signed[31:0] EXMEM_ALURES;
	reg EXMEM_Branch;
	reg EXMEM_LessThan;
	reg EXMEM_Equal;
	reg EXMEM_WriteReg;
	reg EXMEM_WriteMem;
	reg EXMEM_MemToReg;
	reg EXMEM_PCtoReg;
	reg EXMEM_SetLessThan;
	reg EXMEM_Jump;
	reg EXMEM_NotEqual;
	reg[1:0] EXMEM_MemSize;
	reg EXMEM_LoadUns;
	reg EXMEM_ignore;
	reg EXMEM_invalid;
	reg EXMEM_raise_excep;
	reg[3:0] EXMEM_excep_code;
	reg EXMEM_Ret;
	reg[31:0] EXMEM_IBITS;
	reg[1:0] EXMEM_RetFrom;
	reg EXMEM_Wfi;

	reg MEM_raise_excep;
	reg[2:0] MEM_excep_code;

	// Write back stage
	reg[4:0] MEMWB_RD;
	reg[31:0] MEMWB_PC;
	reg signed[31:0] MEMWB_LOAD;
	reg signed[31:0] MEMWB_ALURES;
	reg MEMWB_MSB;
	reg MEMWB_WriteReg;
	reg MEMWB_MemToReg;
	reg MEMWB_PCtoReg;
	reg MEMWB_SetLessThan;
	reg MEMWB_invalid;
	reg MEMWB_ignore;
	reg MEMWB_Jump;

	reg WB_raise_excep;
	reg[2:0] WB_excep_code;

	// Forward
	wire fw_EX_A;
	wire fw_EX_B;
	wire fw_MEM_A_L, fw_MEM_A;
	wire fw_MEM_B_L, fw_MEM_B;

	// CSRs
	reg[31:0] mstatus, mstatush;
	reg[31:0] marchid, mhartid;
	reg[31:0] misa;
	reg[31:0] mvendorid;
	reg[31:0] medeleg, medelegh, mideleg;
	reg[31:0] mir, mip, mie;
	reg[31:0] mscratch;
	reg[31:0] mepc;
	reg[31:0] mcause, mtval, mtvec;
	reg[31:0] mcounteren;
	reg[63:0] mcycle;
	reg[63:0] minstret;
	reg[31:0] mcountinhibit;

	// supervisor CSRs
	reg[31:0] stvec;
	reg[31:0] sval;
	reg[31:0] sepc;
	reg[31:0] scause;
	reg[31:0] scounteren;

	always @(posedge clk)
		if (stage == 1 && mem_ready)
			if (take_branch && new_PC[1:0] != 0 && !stop_IF) begin
				IF_raise_excep <= 1;
				IF_excep_code <= 0;
			end
			else begin
				IF_raise_excep <= 0;
				IF_excep_code <= 0;
			end

	always @(negedge stage) begin
		if (!enable_) begin
			IF_invalid <= reset || IFinvalid;
			IF_ignore <= IFinvalid || reset;
	
		end
	end

	wire IDinv = IF_invalid || reset_internal || IDinvalid || dont_ex_fst || any_excep && !interrupted;
	always @(negedge stage) begin
		if (!enable_) begin
			IFID_invalid <= IDinv;
			IFID_ignore <= EXMEM_Ret || IF_ignore || IDinv;
			IFID_PC <= stop_ID ? IFID_PC : MAR;
			IFID_IR <= mem_out;
		end
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
	wire[1:0] RetFrom;
	wire Wfi;

	wire signed[31:0] alu_res;
	wire signed[31:0] a, b;
	wire signed[31:0] imm;
	wire signed[31:0] write_data;

	wire signed[31:0] atomic_data = csr_eread_data;

	wire no_perm;

	reg take_branch;
	always @(*)
		take_branch <= ~EXMEM_ignore & (EXMEM_Jump | EXMEM_Branch & (EXMEM_NotEqual ? ~EXMEM_ZERO : EXMEM_Equal ? EXMEM_ZERO : EXMEM_LessThan & EXMEM_MSB));

	reg any_branch;
	always @(*)
		any_branch <= IDEX_Branch && ~IDEX_ignore || EXMEM_Branch && ~EXMEM_ignore || IDEX_Jump && ~IDEX_ignore || EXMEM_Jump && ~EXMEM_ignore;

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
		.write_enable(wr && stage == 1),
		.atomic_write_enable(atomic_write_enable && stage == 0)
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
		.Jalr(Jalr),
		.RetFrom(RetFrom),
		.Wfi(Wfi)
	);

	always @(*) begin
		ID_raise_excep <= IFID_ignore ? 0 : ~EXMEM_Ret & (RaiseExcep | no_perm);
		ID_excep_code <= IFID_ignore ? 0 : RaiseExcep ? ExcepCode : 'b10;
	end

	reg[31:0] loaded_val = 0;

	wire signed[31:0] r1 = fw_EX_A ? alu_res : fw_MEM_A ? EXMEM_ALURES : fw_MEM_A_L ? loaded_val : a;
	wire signed[31:0] r2 = fw_EX_B ? alu_res : fw_MEM_B ? EXMEM_ALURES : fw_MEM_B_L ? loaded_val : b;

	reg[11:0] csr_eaddr_id = 0;
	reg[31:0] csr_ewrite_data = 0;
	reg[31:0] csr_eread_data = 0;

	reg counteren_allow;
	always @(*) begin
		if ((EXMEM_ALURES >= 296 && EXMEM_ALURES < 304))
			if (mode == `SUPERV)
				counteren_allow <= mcounteren[1];
			else if (mode == `USER)
				counteren_allow <= scounteren[1] & mcounteren[1];
			else
				counteren_allow <= 1;
		else
			counteren_allow <= 1;
	end

	assign no_perm = (ReadCsrIDe || WriteCsrIDe) && (csr_eaddr_id[11:10] > mode);

	always @(*)
		csr_eaddr_id <= IFID_IR[31:20];

	always @(*) begin
		if (ReadCsrIDe && !no_perm)
			case(csr_eaddr_id)
				'h105:
					csr_eread_data <= scounteren;
				'h300:
					csr_eread_data <= mstatus;
				'h301:
					csr_eread_data <= misa;
				'h302:
					csr_eread_data <= medeleg;
				'h303:
					csr_eread_data <= mideleg;
				'h304:
					csr_eread_data <= mie;
				'h305:
					csr_eread_data <= mtvec;
				'h306:
					csr_eread_data <= mcounteren;
				'h310:
					csr_eread_data <= mstatush;
				'h312:
					csr_eread_data <= medelegh;
				'h340:
					csr_eread_data <= mscratch;
				'h341:
					csr_eread_data <= mepc;
				'h342:
					csr_eread_data <= mcause;
				'h343:
					csr_eread_data <= mtval;
				'h344:
					csr_eread_data <= mip;
				'hb00:
					csr_eread_data <= mcycle[31:0];
				'hb80:
					csr_eread_data <= mcycle[63:32];
				'hb02:
					csr_eread_data <= minstret[31:0];
				'hb82:
					csr_eread_data <= minstret[63:32];
				'h320:
					csr_eread_data <= mcountinhibit;
				default:
					csr_eread_data <= 0;
			endcase
		else
			csr_eread_data <= 0;
	end

	assign deleg =
		(highest_excep >= 34 ? medelegh[highest_excep[4:0]] : medeleg[highest_excep[4:0]]) && !interrupted
		|| interrupted && mideleg[highest_excep[4:0]];

	reg interrupted;
	reg i_;
	wire handle_interrupt = (mip[11] && mie[11] || mip[7] && mie[7]) && mode == `MACHINE || |mip && mode < `MACHINE;

	reg last_interrupted;
	reg can_break;

	always @(negedge clk) begin
		if (!enable_) begin
			if (handle_interrupt && !last_interrupted) begin
				interrupted <= 1;
				can_break <= ~stage;
			end
			else if (~stage && can_break)
				interrupted <= 0;
			else if (stage)
				can_break <= 1;

			last_interrupted <= handle_interrupt;
		end
	end

	always @(posedge clk) begin
		if (interrupt_m && interrupt_type_m && !enable_) begin
			mip[11] <= 1'b1;
			mip[7] <= 1'b0;
		end
		else if (interrupt_m && ~interrupt_type_m && !enable_) begin
			mip[7] <= 1'b1;
			mip[11] <= 1'b0;
		end
	end

	always @(posedge clk) begin
		mip[0] <= 0;
		mip[2] <= 0;
		mip[4] <= 0;
		mip[6] <= 0;
		mip[8] <= 0;
		mip[10] <= 0;
		mip[12] <= 0;
		mip[31:14] <= 0;

		// Other interrupts that aren't implemented yet
		mip[1] <= 0;
		mip[3] <= 0;
		mip[5] <= 0;
		mip[9] <= 0;
		mip[13] <= 0;
	end

	reg[31:0] rr1;
	always @(*)
		if (fw_EX_A)
			rr1 <= alu_res;
		else if (fw_MEM_A_L)
			rr1 <= loaded_val;
		else if (fw_MEM_A)
			rr1 <= EXMEM_ALURES;
		else
			rr1 <= r1;

	reg h;
	reg[31:0] mstatus_;
	always @(posedge clk) begin
		if (stage == 1 && !IFID_ignore && !enable_) begin
			if (WriteCsrIDe && ~stop_ID) begin
				if (CsrOp == 0)
					csr_ewrite_data = CsrSrc ? imm : rr1;
				else if (CsrOp == 1)
					csr_ewrite_data = (CsrSrc ? imm : rr1) | csr_eread_data;
				else if (CsrOp == 2)
					csr_ewrite_data = ~(CsrSrc ? imm : rr1) & csr_eread_data;
				else
					csr_ewrite_data = csr_eread_data;
			end

			if (WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h305)
				mtvec <= csr_ewrite_data;

			h <= interrupted;

			mstatus_ = WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h300 ? csr_ewrite_data : mstatus;
			misa <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h302 ? csr_ewrite_data : misa;
			medeleg <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h302 ? csr_ewrite_data : medeleg;
			mideleg <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h303 ? csr_ewrite_data : mideleg;
			mie <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h304 ? csr_ewrite_data : mie;
			mstatush <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h310 ? csr_ewrite_data : mstatush;
			medelegh <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h312 ? csr_ewrite_data : medelegh;
			mscratch <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h340 ? csr_ewrite_data : mscratch;
			mcounteren <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h306 ? csr_ewrite_data : mcounteren;
			mcountinhibit <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h320 ? csr_ewrite_data : mcountinhibit;
			mcycle <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'b00 ? csr_ewrite_data : mcountinhibit[0] ? mcycle : mcycle + 1;

			if (any_excep && ~(deleg && mode < `MACHINE) && !(interrupted && h))
				mepc <= interrupted && !EXMEM_Wfi ? IFID_PC : EXMEM_PC + 4;
			else if (WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h341)
				mepc <= csr_ewrite_data;
			else if (EXMEM_RetFrom == `SUPERV && mode == `MACHINE && mstatus[12:11] == `SUPERV)
				mepc <= sepc;

			if (EXMEM_RetFrom == `SUPERV && mode == `MACHINE && mstatus[12:11] == `SUPERV)
				mstatus_[12:11] = {1'b0, mstatus[8]};

			mstatus <= mstatus_;

			if (any_excep && ~(deleg && mode < `MACHINE) && !(interrupted && h))
				mcause <= {excep_type, 31'd0} + highest_excep;
			else if (WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h342 && ~no_perm)
				mcause <= csr_ewrite_data;

			if (any_excep && ~(deleg && mode < `MACHINE) && !(interrupted && h))
				mtval <= EXMEM_IBITS;
			else if (WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h343 && ~no_perm)
				mtval <= csr_ewrite_data;

			if (any_excep && deleg && mode < `MACHINE && !(interrupted && h))
				sepc <= interrupted && !EXMEM_Wfi ? EXMEM_PC : EXMEM_PC + 4;

			if (any_excep && deleg && mode < `MACHINE && !(interrupted && h))
				scause <= highest_excep + {excep_type, 31'd0};

			if (any_excep && deleg && mode < `MACHINE && !(interrupted && h))
				sval <= EXMEM_IBITS;

			scounteren <= WriteCsrIDe && ~stop_ID && csr_eaddr_id == 'h106 ? csr_ewrite_data : scounteren;
		end
	end

	always @(posedge clk) begin
		if (EXMEM_Ret && stage == 0 && !enable_)
			xPP <= mode == `MACHINE ? mstatus[12:11] : mode == `SUPERV ? mstatus[8] : `USER;
	end

	// Execution stage

	wire IDEXinv = AtomicWriteReg || reset_internal || IFID_invalid || EXinvalid || any_excep && !interrupted;
	always @(negedge stage) begin
		if (!enable_) begin
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
			IDEX_RetFrom <= RetFrom;
			IDEX_Wfi <= Wfi;
		end
	end

	always @(*) begin
		EX_raise_excep <= 0;
		EX_excep_code <= 0;
	end

	wire illegal_op;

	wire signed[31:0] alu_b = IDEX_AluSrc ? IDEX_IMM : IDEX_B;
	wire[31:0] alu_a = IDEX_PCImm ? IDEX_PC : IDEX_A;
	wire zero;

	reg excep_type;

	always @(*)
		if (interrupted) begin
			excep_type <= 1'b1;
			highest_excep <= interrupt_type_m ? 'd11 : 'd13;
		end
		else if (MEM_raise_excep) begin
			if (MEM_excep_code == 'd0)
				highest_excep <= MEM_excep_code;
			else if (EXMEM_raise_excep)
				highest_excep <= EXMEM_excep_code;
			else
				highest_excep <= 0;

			excep_type <= 1'b0;
		end
		else if (EXMEM_raise_excep) begin
			excep_type <= 1'b0;
			highest_excep <= EXMEM_excep_code;
		end
		else begin
			excep_type <= 1'b0;
			highest_excep <= 0;
		end

	alu alu_(.clk(clk), .reset(reset), .alu_op(IDEX_AluOp), .r1(alu_a), .r2(alu_b), .res(alu_res), .zero(zero), .illegal_op(illegal_op));

	wire signed[31:0] subAB = (IDEX_A >= 0 ? IDEX_A : SubABU ? $unsigned(IDEX_A) : IDEX_A) - (IDEX_B >= 0 ? IDEX_B : SubABU ? $unsigned(IDEX_B) : IDEX_B);

	// Memory stage

	wire MEMinv = reset_internal || IDEX_invalid || MEMinvalid || any_excep && !interrupted;
	always @(negedge stage) begin
		if (!enable_) begin
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
			EXMEM_RetFrom <= IDEX_RetFrom;
			EXMEM_Wfi <= IDEX_Wfi;
		end
	end

	assign new_PC = take_branch ? EXMEM_ALURES : PC + 4;

	wire UBE = mstatus[6];
	wire SBE = mstatush[4];
	wire MBE = mstatush[5];

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
		if (~EXMEM_ignore && stage == 0 && ((EXMEM_MemToReg || EXMEM_WriteMem) && (EXMEM_MemSize == `HALF && EXMEM_ALURES[0] != 0 || EXMEM_MemSize == `WORD && EXMEM_ALURES[1:0] != 0) || take_branch && new_PC[1:0] != 0)) begin
			MEM_raise_excep <= 1;
			MEM_excep_code <= take_branch && new_PC[1:0] != 0 ? 0 : EXMEM_MemToReg ? 'd4 : 'd6;
		end
		else if (!counteren_allow || ~EXMEM_ignore && mode < `MACHINE && EXMEM_ALURES >= 296 && EXMEM_ALURES < 316 && EXMEM_WriteMem) begin
			MEM_raise_excep <= 1;
			MEM_excep_code <= 2;
		end
		else begin
			MEM_raise_excep <= 0;
			MEM_excep_code <= 0;
		end

	assign mem_write_enable =
		(~MEM_raise_excep & ~EXMEM_raise_excep) & EXMEM_WriteMem & ~EXMEM_ignore & ~stage && ~reset_internal;
	assign mem_read_enable =
		((~MEM_raise_excep & ~EXMEM_raise_excep) & EXMEM_MemToReg & ~EXMEM_ignore & ~stage | stage) && ~reset_internal;
	assign addr = stage == 0 ? EXMEM_ALURES : MAR;
	assign data_size = stage == 0 ? EXMEM_MemSize : `WORD;

	wire little_endian = mode == `MACHINE && ~MBE || mode == `SUPERV && ~SBE || mode == `USER && ~UBE;
	wire big_endian = mode == `MACHINE && MBE || mode == `SUPERV && SBE || mode == `USER && UBE;

	always @(*) begin
		if (stage == 0) begin
			if (little_endian)
				case (EXMEM_MemSize)
					'd1:
						mem_in <= {EXMEM_OTHER[7:0], 24'd0};
					'd2:
						mem_in <= {EXMEM_OTHER[15:0], 16'd0};
					'd3:
						mem_in <= EXMEM_OTHER;
					default:
						mem_in <= 0;
				endcase
			else if (big_endian)
				case (EXMEM_MemSize)
					'd1:
						mem_in <= {EXMEM_OTHER[7:0], 24'd0};
					'd2:
						mem_in <= {EXMEM_OTHER[7:0], EXMEM_OTHER[15:8], 16'd0};
					'd3:
						mem_in <= {EXMEM_OTHER[7:0], EXMEM_OTHER[15:8], EXMEM_OTHER[23:16], EXMEM_OTHER[31:24]};
					default:
						mem_in <= 0;
				endcase
			else
				mem_in <= 0;
		end
		else
			mem_in <= 0;
	end

	/*
	* The memory module must always read a word regardless of
	* the size of the data being read.
	*/
	wire[1:0] offset_data = EXMEM_ALURES[1:0];
	always @(posedge stage)
		if (little_endian)
			case(EXMEM_MemSize)
				`BYTE:
					if (offset_data == 0)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[31]}}, mem_out[31:24]};
					else if (offset_data == 1)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[23]}}, mem_out[23:16]};
					else if (offset_data == 2)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[15]}}, mem_out[15:8]};
					else
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[7]}}, mem_out[7:0]};
				`HALF:
					if (offset_data == 0)
						loaded_val <= {{16{!EXMEM_LoadUns & mem_out[31]}}, mem_out[31:16]};
					else if (offset_data == 2)
						loaded_val <= {{16{!EXMEM_LoadUns & mem_out[15]}}, mem_out[15:0]};
					else
						loaded_val <= 0;
				`WORD:
					loaded_val <= mem_out;
			endcase
		else if (big_endian)
			case (EXMEM_MemSize)
				`BYTE:
					if (offset_data == 0)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[31]}}, mem_out[31:24]};
					else if (offset_data == 1)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[23]}}, mem_out[23:16]};
					else if (offset_data == 2)
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[15]}}, mem_out[15:8]};
					else
						loaded_val <= {{24{!EXMEM_LoadUns & mem_out[7]}}, mem_out[7:0]};
				`HALF:
					if (offset_data == 0)
						loaded_val <= {{16{!EXMEM_LoadUns & mem_out[23]}}, mem_out[23:16], mem_out[31:24]};
					else if (offset_data == 2)
						loaded_val <= {{16{!EXMEM_LoadUns & mem_out[7]}}, mem_out[7:0], mem_out[15:8]};
					else
						loaded_val <= 0;
				`WORD:
					loaded_val <= {mem_out[7:0], mem_out[15:8], mem_out[23:16], mem_out[31:24]};
			endcase

	// Write back stage

	wire WBinv = reset_internal || EXMEM_invalid || WBinvalid;
	always @(negedge stage) begin
		if (!enable_) begin
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
			MEMWB_LOAD <= loaded_val;
			MEMWB_Jump <= EXMEM_Jump;
		end
	end

	always @(*) begin
		WB_raise_excep <= 0;
		WB_excep_code <= 0;
	end

	assign write_data =
		MEMWB_PCtoReg ?
			(MEMWB_Jump ? MEMWB_PC + 4 : MEMWB_PC) :
			MEMWB_SetLessThan ?
				{31'b0, MEMWB_MSB} :
				MEMWB_MemToReg ?
					MEMWB_LOAD :
					MEMWB_ALURES;

	wire state_reset = state == `RESET;
	wire csr_write_mstatus = WriteCsrIDe && (funct12 == 'h300 || funct12 == 'h310);

	assign any_excep = MEM_raise_excep || EXMEM_raise_excep || interrupted;
	hazard_Detection_Unit haz(
		.clk(clk),
		.reset(state_reset),
		.go_to_next(stage && mem_ready),
		.took_branch(take_branch),
		.MEM_invalid(EXMEM_ignore),
		.EX_invalid(IDEX_ignore),
		.is_load_EX(IDEX_MemToReg),
		.is_load_MEM(EXMEM_MemToReg),
		.is_store_EX(IDEX_WriteMem),
		.csr_write_mstatus(csr_write_mstatus),
		.any_excep(any_excep && !interrupted),
		.any_branch(any_branch),
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
		.csr_write(AtomicWriteReg),
		.is_branch_EX(IDEX_Jump || IDEX_Branch),
		.EX_PC(IDEX_PC),
		.ID_PC(IFID_PC),
		.MEM_PC(EXMEM_PC),
		.interrupt(interrupted)
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
