module csr(input clk);

	localparam mem_size = 48;

	reg[7:0] inst_mem[mem_size - 1:0];
	reg[7:0] data_mem[31:0];

	reg[31:0] i_mem_out = 0;
	reg[31:0] data_mem_out;
	wire[31:0] data_mem_in;

	wire data_mem_ren, data_mem_wen;
	wire[31:0] addr, d_addr;

	always @(posedge clk) begin
		if (data_mem_wen)
			{data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]} <= data_mem_in;

		data_mem_out <= {data_mem[d_addr], data_mem[d_addr + 1], data_mem[d_addr + 2], data_mem[d_addr + 3]};

		i_mem_out <= {inst_mem[addr + 3], inst_mem[addr + 2], inst_mem[addr + 1], inst_mem[addr]};
	end

	cpu CPU(
		.clk(clk),
		.d_addr(d_addr),
		.addr(addr),
		.i_mem_out(i_mem_out),
		.data_mem_in(data_mem_in),
		.data_mem_out(data_mem_out),
		.data_mem_write_enable(data_mem_wen)
	);

	integer i;
	initial begin
		$readmemh("tests/csr/mem.hex", inst_mem);
		for (i = 0; i < 32; i = i + 1)
			data_mem[i] <= 0;
	end
endmodule
