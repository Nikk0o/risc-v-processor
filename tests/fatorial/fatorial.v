module fatorial(input clk);

	localparam inst_mem_size = 36;

	reg[7:0] mem[255:0];

	wire[31:0] mem_in;
	reg[31:0] mem_out = 0;
	wire mem_wen, mem_ren;
	wire[31:0] addr;

	always @(negedge clk) begin
		if (mem_wen)
			{mem[addr], mem[addr + 1], mem[addr + 2], mem[addr + 3]} <= mem_in;

		if (mem_ren)
			mem_out <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr + 0]};
	end

	NK0w0 #(
		.ram_bus_width(32),
		.ram_data_width(8)
	) CPU(
		.clk(clk),
		.reset(1'b0),
		.ram_write_enable(mem_wen),
		.ram_read_enable(mem_ren),
		.ram_address(addr),
		.ram_out(mem_out),
		.ram_in(mem_in)
	);

	integer i;
	initial begin
		for (i = 128; i < 256; i = i + 1)
			mem[i] = 0;
		$readmemh("tests/fatorial/mem.hex", mem);

		{mem[124], mem[125], mem[126], mem[127]} = 32'd5;
	end

endmodule
