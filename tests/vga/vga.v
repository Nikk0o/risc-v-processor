module vga(
	input clk,
	`ifdef FPGA input reset, `endif
	output reg[2:0] rgb,
	output hs,
	output vs);

	reg[9:0] cx = 0, cy = 0;
`ifdef FPGA
	wire vga_clk;
`else
	reg vga_clk = 0;
`endif

`ifdef FPGA
	 rPLL #( // For GW1NR-9C C6/I5 (Tang Nano 9K proto dev board)
	  .FCLKIN("27"),
	  .IDIV_SEL(5), // -> PFD = 4.5 MHz (range: 3-400 MHz)
	  .FBDIV_SEL(6), // -> CLKOUT = 31.5 MHz (range: 3.125-600 MHz)
	  .ODIV_SEL(32) // -> VCO = 1008 MHz (range: 400-1200 MHz)
	) pll (.CLKOUTP(), .CLKOUTD(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0),
	  .CLKIN(clk), // 27 MHz
	  .CLKOUT(vga_clk), // 31.5 MHz
	  .LOCK(pll_lock)
	);
`endif

`ifndef FPGA
	integer i;
	integer cnt = 0;
	reg reset = 1;
	always begin
		#2;
		cnt = cnt + 1;
		vga_clk <= ~vga_clk;
		`ifndef YOSYS
		if (cnt == 30000)
			$finish;
		`endif

		for (i = 0; i < 32; i = i + 1) begin
			$dumpvars(0, CPU.regs.regs[i]);
			$dumpvars(0, inst_mem[i]);
		end
		$dumpvars(0, CPU, data_mem[0], data_mem[1], data_mem[2], data_mem[3], rgb);
	end
`endif

	always @(posedge vga_clk) begin
		cx <= cx == 800 ? 0 : cx + 1;
		cy <= cx == 800 ? cy == 525 ? 0 : cy + 1 : cy;
	end

	assign hs = ~(cx >= 640 + 16 && cx < 640 + 16 + 96);
	assign vs = (cy >= 480 + 10 && cy < 480 + 10 + 2);

	// CPU IO
	
	reg[7:0] inst_mem[43:0];
	reg[7:0] data_mem[31:0];

	wire w_en;
	wire[31:0] addr;
	wire[31:0] d_addr;
	wire[31:0] d_mem_in;
	reg[31:0] i_mem_out = 'h00000293;
	reg[31:0] d_mem_out = 0;

`ifdef FPGA
	reg cpu_clk = 0;
	integer cntt = 0;
	always @(posedge clk)
		if (~reset) begin
			cpu_clk <= 0;
			cntt <= 0;
		end
		else if (cntt == 26) begin
			cpu_clk <= ~cpu_clk;
			cntt <= 0;
		end
		else
			cntt <= cntt + 1;
`else
	wire cpu_clk = vga_clk;
`endif

	wire[1:0] size;
	integer h;

	always @(posedge cpu_clk) begin
		if (w_en) begin
			data_mem[d_addr + 3] <= d_mem_in[7:0];
			data_mem[d_addr + 2] <= d_mem_in[15:8];
			data_mem[d_addr + 1] <= d_mem_in[23:16];
			data_mem[d_addr] <= d_mem_in[31:24];
		end
	end

	always @(posedge vga_clk)
		rgb <= {cpu_clk, 1'b0, |{data_mem[3], data_mem[2], data_mem[1], data_mem[0]}};

	always @(posedge cpu_clk) begin
		i_mem_out <= addr > 40 ? 0 : {inst_mem[addr], inst_mem[addr + 1], inst_mem[addr + 2], inst_mem[addr + 3]};
		d_mem_out <= {data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]};
	end

	wire nr = ~reset;
	cpu CPU(.clk(cpu_clk), .d_mem_in(d_mem_in), .d_mem_out(d_mem_out), .i_mem_out(i_mem_out), .addr(addr), .d_addr(d_addr), .d_mem_wen(w_en), .reset(nr), .write_data_size(size));

	integer zz;
	initial begin
		$dumpfile("tmp/a.vcd");
		$readmemh("tests/vga/mem.hex", inst_mem, 0, 43);
		for (zz = 0; zz < 32; zz = zz + 1)
			data_mem[zz] = 2 ** zz;
	end

endmodule
