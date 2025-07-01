module vga
	`ifdef YOSYS
	(
		input clk,
		output[2:0] color,
		output[1:0] sync
	)
	`endif
	;

	localparam inst_mem_size = 184;

	reg[9:0] cx = 0, cy = 0;
	wire hsync, vsync;

	wire pix_clk;

	integer i;

	`ifdef YOSYS
		
	`else
		reg clk = 0;
		integer loop_cnt = 0;

		always begin
			#2;

			clk <= ~clk;

			if (clk)
				loop_cnt <= loop_cnt + 1;

			if (loop_cnt == 5000)
				$finish;

			$dumpvars(0, CPU, cx, cy, hsync, vsync, data_mem[1], data_mem[3], data_mem[4], data_mem[5]);

			for (i = 0; i < 32; i = i + 1)
				$dumpvars(0, CPU.regs.regs[i]);
		end

		assign pix_clk = clk;
	`endif

	always @(posedge pix_clk) begin
		cx <= cx == 839 ? 0 : cx + 1;
		cy <= cx == 839 ? cy == 499 ? 0 : cy + 1 : cy;
	end

	assign hsync = cx >= 640 + 16 && cx < 640 + 16 + 64;
	assign vsync = cy >= 480 + 1 && cx < 480 + 1 + 3;

	reg[7:0] inst_mem[inst_mem_size - 1:0];
	reg[7:0] data_mem[255:0];

	reg[31:0] inst_mem_out = 0;
	reg[31:0] data_mem_out = 0;
	wire[31:0] data_mem_in;
	wire[31:0] addr, d_addr;

	wire data_mem_wen, data_mem_ren, inst_mem_ren;
	wire[1:0] memsize;

	always @(posedge clk) begin
		if (inst_mem_ren)
			inst_mem_out <= {inst_mem[addr + 3], inst_mem[addr + 2], inst_mem[addr + 1], inst_mem[addr]};

		if (data_mem_ren)
			data_mem_out <= {data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]};

		if (data_mem_wen)
			if (memsize == 1)
				data_mem[d_addr] <= data_mem_in[7:0];
			else if (memsize == 2)
				{data_mem[d_addr], data_mem[d_addr + 1]} <= data_mem_in[15:0];
			else if (memsize == 3)
				{data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]} <= data_mem_in;

			data_mem[1] <= {7'h0, cx >= 640 || cy >= 480};
	end

	cpu CPU(
		.clk(clk),
		.reset(1'b0),
		.i_mem_out(inst_mem_out),
		.data_mem_out(data_mem_out),
		.data_mem_in(data_mem_in),
		.addr(addr),
		.d_addr(d_addr),
		.w_data_size(memsize),
		.inst_mem_read_enable(inst_mem_ren),
		.data_mem_write_enable(data_mem_wen),
		.data_mem_read_enable(data_mem_ren)
	);

	initial begin
		$readmemh("tests/vga/inst_mem.hex", inst_mem, 0, inst_mem_size - 1);
		$dumpfile("tmp/a.vcd");

		for (i = 0; i < 256; i = i + 1)
			data_mem[i] <= 0;
	end

endmodule
