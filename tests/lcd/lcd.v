module lcd
	`ifdef YOSYS 
	(
	input clk,
	output[10:0] lcd_output)
	`endif
	;

	parameter inst_mem_size = 1472;

	`ifndef YOSYS
	reg clk = 0;
	integer loop_cnt = 0;

	integer j;
	always begin
		#2;
		clk <= ~clk;

		if (clk)
			loop_cnt <= loop_cnt + 1;

		if (loop_cnt == 5000)
			$finish;

		$dumpvars(0, CPU, data_mem[260], data_mem[261]);
		for (j = 132; j < 132 + 12; j = j + 1)
			$dumpvars(0, data_mem[j]);

		for (j = 0; j < 32; j = j + 1)
			$dumpvars(0, CPU.regs.regs[j]);
	end
	`endif

	reg[7:0] data_mem[261:0];
	reg[7:0] inst_mem[inst_mem_size - 1:0];

	wire[31:0] data_mem_in;
	reg[31:0] data_mem_out = 0;
	reg[31:0] inst_mem_out = 0;
	wire[1:0] memsize;
	wire[31:0] addr;
	wire[31:0] d_addr;

	wire i_mem_ren, d_mem_ren, d_mem_wen;

	always @(posedge clk) begin
		if (i_mem_ren)
			inst_mem_out <= {inst_mem[addr + 3], inst_mem[addr + 2], inst_mem[addr + 1], inst_mem[addr]};

		if (d_mem_ren)
			data_mem_out <= {data_mem[d_addr], d_addr >= 258 ? 8'd0 : data_mem[d_addr + 1], d_addr >= 258 ? 8'd0 : data_mem[d_addr + 2], d_addr >= 258 ? 8'd0 : data_mem[d_addr + 3]};

		if (d_mem_wen)
			if (memsize == 3)
				{data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]} <= data_mem_in;
			else if (memsize == 2)
				{data_mem[d_addr], data_mem[d_addr + 1]} <= data_mem_in[15:0];
			else if (memsize == 1)
				data_mem[d_addr] <= data_mem_in;
	end

	cpu CPU(
		.clk(clk),
		.data_mem_in(data_mem_in),
		.data_mem_out(data_mem_out),
		.i_mem_out(inst_mem_out),
		.addr(addr),
		.d_addr(d_addr),
		.data_mem_read_enable(d_mem_ren),
		.data_mem_write_enable(d_mem_wen),
		.inst_mem_read_enable(i_mem_ren),
		.w_data_size(memsize)
	);

	`ifdef YOSYS
		wire[10:0] lcd_command = {data_mem[260][2:0], data_mem[261]};
		assign lcd_output = lcd_command;
	`endif

	integer i;
	initial begin
		$readmemh("tests/lcd/inst_mem.hex", inst_mem, 0, inst_mem_size - 1);
		$dumpfile("tmp/a.vcd");

		for (i = 0; i < 262; i = i + 1)
			data_mem[i] <= 0;
	end

endmodule
