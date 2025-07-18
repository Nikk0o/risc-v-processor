module fatorial(input clk);

	parameter mem_size = 1028;

	reg[7:0] mem[mem_size - 1:0];

	wire wen, ren;
	wire[31:0] mem_in, addr;
	reg[31:0] mem_out;

	always @(negedge clk) begin
		if (wen)
			{mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]} <= mem_in;

		if (ren)
			mem_out <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
	end

	NK0W0 #(
		.ram_bus_width(32),
		.ram_data_width(8),
		.starting_point(312)
	) CPU(
		.clk(clk),
		.reset(1'b0),
		.enable_(1'b0),
		.ram_write_enable(wen),
		.ram_read_enable(ren),
		.ram_address(addr),
		.ram_out(mem_out),
		.ram_in(mem_in),

		.external_interrupts(0)
	);

	initial
		$readmemh("tests/fatorial/mem.hex", mem);
endmodule
