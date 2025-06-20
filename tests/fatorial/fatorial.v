module fatorial;

	parameter mem_size = 10 * 4;

	reg clk = 0;
	integer loop_cnt = 0;
	integer i = 0;
	always begin
		#2;
		clk <= ~clk;

		if (clk)
			loop_cnt <= loop_cnt + 1;

		if (loop_cnt == 5000)
			$finish;

		$dumpvars(0, CPU, data_mem[0], data_mem[1], data_mem[2], data_mem[3]);
		for (i = 0; i < 32; i = i + 1)
			$dumpvars(0, CPU.regs.regs[i]);
	end

	reg[7:0] inst_mem[mem_size-1:0];
	reg[7:0] data_mem[31:0];

	wire[31:0] addr, d_addr;
	reg[31:0] data_mem_out = 0;
	reg[31:0] inst_mem_out = 0;
	wire[31:0] data_mem_in;
	wire[1:0] w_data_size;
	wire data_mem_wen, inst_mem_ren;
	wire data_mem_ren;

	always @(posedge clk) begin
		if (i_mem_ren)
			inst_mem_out <= addr > mem_size - 4 ? 'h0 : {inst_mem[addr], inst_mem[addr + 1], inst_mem[addr + 2], inst_mem[addr + 3]};

		if (data_mem_ren)
			data_mem_out <= {data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]};

		if (data_mem_wen)
			case(w_data_size)
				'b01:
					data_mem[d_addr] <= data_mem_in[7:0];
				'b10:
					{data_mem[d_addr], data_mem[d_addr + 1]} <= data_mem_in[15:0];
				'b11:
					{data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]} <= data_mem_in;
			endcase
	end

	cpu CPU(
		.clk(clk),
		.reset(1'b0),
		.data_mem_out(data_mem_out),
		.data_mem_in(data_mem_in),
		.w_data_size(w_data_size),
		.i_mem_out(inst_mem_out),
		.data_mem_write_enable(data_mem_wen),
		.data_mem_read_enable(data_mem_ren),
		.inst_mem_read_enable(i_mem_ren),
		.addr(addr),
		.d_addr(d_addr));

	integer j;
	initial begin
		$readmemh("tests/fatorial/mem.hex", inst_mem, 0, mem_size - 1);
		$dumpfile("tmp/a.vcd");
		for (j = 0; j < 32; j = j + 1)
			data_mem[j] <= 0;
	end

endmodule
