module registers(input clk,
				 input reset,
				 input[4:0] rs1,
				 input[4:0] rs2,
				 input[4:0] rd,
				 input[4:0] atomic_rd,
				 input write_enable,
				 input atomic_write_enable,
				 input signed[31:0] write_data,
				 input signed[31:0] atomic_write_data,
				 output signed[31:0] r1,
				 output signed[31:0] r2);

	reg signed[31:0] regs[31:0];
	reg[31:0] invalid_r = 0;
	wire wen = write_enable && |rd || atomic_write_enable && |atomic_rd;

	always @(posedge clk) begin
		if (reset) begin
			invalid_r <= {{31{1'b1}}, 1'b0};
		end
		else begin
			if (wen)
				if (atomic_write_enable && |atomic_rd) begin
					if (write_enable && |rd) begin
						if (rd == atomic_rd)
							regs[atomic_rd] <= atomic_write_data;
						else begin
							regs[atomic_rd] <= atomic_write_data;
							regs[rd] <= write_data;

							invalid_r[rd] <= 0;
						end
					end

					invalid_r[atomic_rd] <= 0;
				end
				else begin
					regs[rd] <= write_data;
					invalid_r[rd] <= 0;
				end
		end
	end

	assign r1 = rs1 == atomic_rd && |atomic_rd && atomic_write_enable ? atomic_write_data : rs1 == rd && |rd && write_enable ? write_data : invalid_r[rs1] ? 32'd0 : regs[rs1];
	assign r2 = rs2 == atomic_rd && |atomic_rd && atomic_write_enable ? atomic_write_data : rs2 == rd && |rd && write_enable ? write_data : invalid_r[rs2] ? 32'd0 : regs[rs2];

	integer i;
	initial
		for (i = 0; i < 32; i = i + 1)
			regs[i] = 0;

endmodule

module CSRs(
	input clk,
	input[11:0] expl_addr_r,
	input[47:0] impl_addrs_r,
	input[11:0] expl_addr_w,
	input[11:0] impl_addr_w,
	input write_enable,
	input expl_read_enable,
	input[3:0] impl_read_enable,
	input[31:0] write_data,
	input[1:0] mode,
	output reg[31:0] expl_csr = 0,
	output reg[127:0] impl_csr = 0,
	output reg no_permission = 0
);

	// Machine registers
	reg[31:0] misa = 0;
	reg[31:0] mvendorid = 0;
	reg[31:0] marchid = 0;
	reg[31:0] mhartid = 0;
	reg[31:0] mstatus = 0, mstatush = 0;
	reg[31:0] medeleg = 0, medelegh = 0, mideleg = 0;
	reg[31:0] mir = 0, mip = 0, mie = 0;

	reg[31:0] mscratch = 0;
	reg[31:0] mepc = 0;

	reg[31:0] mcause = 0;
	reg[31:0] mtval = 0;
	reg[31:0] mconfigptr = 0;

	reg[31:0] mtvec = 0;

	reg[31:0] mtime = 0, mtimecmp = 0;

	// Add mcycle and minstret and mcounteren

	wire right_mode = (write_enable || expl_read_enable) && expl_addr_w[9:8] <= mode;

	// Implicit reads from CSRs
	genvar i;
	generate
		for (i = 0; i < 4; i = i + 1)
			always @(*) begin
				if (impl_read_enable[i])
					case(impl_addrs_r[(i + 1)*12 - 1:i*12])
						'h300:
							impl_csr[32*(i + 1) - 1:32*i] <= mstatus;
						'h301:
							impl_csr[32*(i + 1) - 1:32*i] <= misa;
						'h302:
							impl_csr[32*(i + 1) - 1:32*i] <= medeleg;
						'h303:
							impl_csr[32*(i + 1) - 1:32*i] <= mideleg;
						'h304:
							impl_csr[32*(i + 1) - 1:32*i] <= mie;
						'h305:
							impl_csr[32*(i + 1) - 1:32*i] <= mtvec;
						'h310:
							impl_csr[32*(i + 1) - 1:32*i] <= mstatush;
						'h312:
							impl_csr[32*(i + 1) - 1:32*i] <= medelegh;
						'h340:
							impl_csr[32*(i + 1) - 1:32*i] <= mscratch;
						'h341:
							impl_csr[32*(i + 1) - 1:32*i] <= mepc;
						'h342:
							impl_csr[32*(i + 1) - 1:32*i] <= mcause;
						'h343:
							impl_csr[32*(i + 1) - 1:32*i] <= mtval;
						'h344:
							impl_csr[32*(i + 1) - 1:32*i] <= mip;
						default:
							impl_csr[32*(i + 1) - 1:32*i] <= 0;
					endcase
			end
	endgenerate

	always @(posedge clk)
		no_permission <= mode < expl_addr_w[11:10] && (write_enable || expl_read_enable);

	// Explicit writes to CSRs
	always @(posedge clk) begin
		case(mode)
			`MACHINE: begin
				if (right_mode && write_enable && expl_addr_w[11:10] <= 2'b11)
					case(expl_addr_w)
						'h300:
							mstatus <= write_data;
						'h301:
							misa <= write_data;
						'h302:
							medeleg <= write_data;
						'h303:
							mideleg <= write_data;
						'h304:
							mie <= write_data;
						'h305:
							mtvec <= write_data;
						'h310:
							mstatush <= write_data;
						'h312:
							medelegh <= write_data;
						'h340:
							mscratch <= write_data;
						'h341:
							mepc <= write_data;
						'h342:
							mcause <= write_data;
						'h343:
							mtval <= write_data;
						'h344:
							mip <= write_data;
					endcase
			end
			`SUPERV: begin
			end
			`USER: begin
			end
			default: begin
			end
		endcase
	end

	// Explicit reads from CSRs
	always @(*) begin
		case(mode)
			`MACHINE: begin
				if (expl_read_enable)
					case(expl_addr_r)
						'h300:
							expl_csr<= mstatus;
						'h301:
							expl_csr <= misa;
						'h302:
							expl_csr <= medeleg;
						'h303:
							expl_csr <= mideleg;
						'h304:
							expl_csr <= mie;
						'h305:
							expl_csr <= mtvec;
						'h310:
							expl_csr <= mstatush;
						'h312:
							expl_csr <= medelegh;
						'h340:
							expl_csr <= mscratch;
						'h341:
							expl_csr <= mepc;
						'h342:
							expl_csr <= mcause;
						'h343:
							expl_csr <= mtval;
						'h344:
							expl_csr <= mip;
						default:
							expl_csr <= 0;
					endcase
			end
			`SUPERV: begin
			end
			`USER: begin
			end
			default: begin
			end
		endcase
	end

endmodule
