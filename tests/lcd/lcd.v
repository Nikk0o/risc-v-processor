module lcd(
	input clk,
	output[31:0] lcd_in
);
	parameter mem_size = 4096 * 2;

	reg[7:0] mem[mem_size - 1:0];

	reg[7:0] mem_out;
	wire ren, wen;
	wire[7:0] mem_in;
	wire[31:0] addr;

	wire dev_ren, dev_wen;
	wire[31:0] dev_addr, dev_in;
	wire[7:0] dev_out;

	reg[31:0] dev_data;

	assign dev_out = dev_data;
	assign lcd_in = dev_data;

	always @(negedge clk) begin
		if (wen)
			mem[{addr[31:2], 2'b00} + 3 - addr[1:0]] <= mem_in;
		if (dev_wen)
			dev_data <= dev_in;

		if (ren)
			mem_out <= addr >= mem_size ? 0 : mem[{addr[31:2], 2'b00} + 3 - addr[1:0]];
		if (dev_ren)
			mem_out <= {addr[31:2], 2'b00} == 40 ? dev_data : 0;
	end

	NK0W0 #(
		.starting_point('h138),
		.ram_bus_width(8),
		.ram_data_width(8)
	) CPU(
		.clk(clk),
		.reset(1'b0),
		.enable_(0),
		.ram_out(mem_out),
		.ram_in(mem_in),
		.ram_write_enable(wen),
		.ram_read_enable(ren),
		.ram_address(addr),
		.external_interrupts(0),

		.device_input(dev_in),
		.device_output(dev_out),
		.device_write_enable(dev_wen),
		.device_read_enable(dev_ren),
		.device_address(dev_addr)
	);

	integer i;
	initial begin
		for (i = 0; i < 'h138; i = i + 1)
			mem[i] <= 0;
		$readmemh("tests/lcd/mem.hex", mem);
		$dumpfile("tmp/a.vcd");
	end

endmodule
