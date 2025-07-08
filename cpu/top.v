module NK0w0(
	input clk,
	input reset,

	output ram_write_enable,
	output ram_read_enable,
	output reg[31:0] ram_address,
	input[ram_bus_width - 1:0] ram_out,
	output reg[ram_bus_width - 1:0] ram_in
);

	parameter ram_bus_width = 128;
	parameter ram_data_width = 8;
	parameter invert_endian = 1;

	reg done_fetch;

	wire ren, wen;
	wire[127:0] ram_in_i;
	wire[31:0] ram_addr;
	reg[127:0] mem_data;

	generate
		if (ram_bus_width == 128) begin
			always @(*)
				done_fetch <= 1;
			always @(*)
				ram_in = ram_in_i;
			always @(*)
				ram_address = {ram_addr[31:7], 7'd0};

			always @(*)
				mem_data = ram_out;
		end
		else begin
			reg[5:0] mem_word = 1;

			always @(posedge clk) begin
				if (wen | ren)
					mem_word <= mem_word == 128 / ram_bus_width ? 1 : mem_word + 1;
				else
					mem_word <= 1;
			end

			always @(posedge clk)
				done_fetch <= mem_word == 128 / ram_bus_width;

			always @(posedge clk)
				if (ren)
					mem_data[127 - (mem_word - 1) * ram_bus_width:128 - mem_word * ram_bus_width] <= ram_out;

			always @(*)
				if (ram_data_width == 8)
					ram_address <= ram_addr[31:4] * 16 + (mem_word - 1) * (ram_bus_width / ram_data_width);
				else if (ram_data_width == 16)
					ram_address <= ram_addr[31:3] * 8 + (mem_word - 1) * (ram_bus_width / ram_data_width);
				else if (ram_data_width == 32)
					ram_address <= ram_addr[31:2] * 4 + (mem_word - 1) * (ram_bus_width / ram_data_width);
				else if (ram_data_width == 64)
					ram_address <= ram_addr[31:1] * 2 + (mem_word - 1) * (ram_bus_width / ram_data_width);
				else
					ram_address <= 'hx;

			always @(negedge clk)
				if (wen)
					ram_in <= ram_in_i[127 - (mem_word - 1) * ram_bus_width:128 - mem_word * ram_bus_width];
		end
	endgenerate

	wire cpu_wen, cpu_ren;
	wire[1:0] cpu_memsize;
	wire[31:0] cpu_address;
	wire[31:0] cpu_data_out;
	wire[31:0] cpu_data_in;
	wire cache_hit;
	wire n_cache_hit;

	L1 cache(
		.clk(clk),
		.reset(reset),
		.read_enable(cpu_ren),
		.write_enable(cpu_wen),
		.memsize(cpu_memsize),
		.address(cpu_address),
		.din(cpu_data_out),
		.dout(cpu_data_in),
		.busy(n_cache_hit),
		.ram_out(mem_data),
		.ram_in(ram_in_i),
		.busy_l(~done_fetch),
		.ram_ren(ren),
		.ram_wen(wen),
		.ram_addr(ram_addr)
	);

	assign cache_hit = ~n_cache_hit;

	cpu #(
		.invert_endian(invert_endian)
	) CPU(
		.clk(clk),
		.reset(reset),
		.mem_out(cpu_data_in),
		.mem_in(cpu_data_out),
		.addr(cpu_address),
		.data_size(cpu_memsize),
		.mem_write_enable(cpu_wen),
		.mem_read_enable(cpu_ren),
		.mem_ready(cache_hit)
	);

	assign ram_write_enable = wen;
	assign ram_read_enable = ren;

endmodule
