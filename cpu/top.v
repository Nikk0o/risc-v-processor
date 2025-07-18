module NK0W0(
	input clk,
	input reset,
	input enable_,

	output ram_write_enable,
	output ram_read_enable,
	output reg[31:0] ram_address,
	input[ram_bus_width - 1:0] ram_out,
	output[ram_bus_width - 1:0] ram_in,

	input[31:0] device_output,
	output[31:0] device_input,
	output device_write_enable,
	output device_read_enable,
	output[31:0] device_address,

	input[15:0] external_interrupts
);

	parameter ram_bus_width = 32;
	parameter ram_data_width = 8;
	parameter starting_point = 0;

	reg done_fetch;

	wire ren, wen;
	wire[127:0] ram_in_i;
	wire[31:0] ram_addr;
	reg[127:0] mem_data;

	reg[63:0] mtime;
	reg[63:0] mtimecmp;

	localparam end_plic = 40;
	localparam end_devs = end_plic + 256;

	wire access_device = (cpu_ren || cpu_wen) && cpu_address >= end_plic && cpu_address < end_devs;
	wire access_mtime = (cpu_ren || cpu_wen) && (cpu_address == end_devs || cpu_address == end_devs + 4);
	wire access_mtimecmp = (cpu_ren || cpu_wen) && (cpu_address == end_devs + 8 || cpu_address == end_devs + 12);
	wire access_plic = (cpu_ren || cpu_wen) && cpu_address < end_plic;
	wire mtime_bigger = mtime > mtimecmp;

	wire mtime_interrupt_enable;

	always @(posedge clk) begin
		if (access_mtime && cpu_wen)
			if (cpu_address == end_devs)
				mtime[63:32] <= cpu_data_out;
			else
				mtime[31:0] <= cpu_data_out;
		else
			mtime <= mtime + 1;

		if (access_mtimecmp && cpu_wen)
			if (cpu_address == end_devs + 8)
				mtimecmp[63:32] <= cpu_data_out;
			else
				mtimecmp[31:0] <= cpu_data_out;
	end

	assign mtime_interrupt_enable = mtime_bigger;

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
				if (!enable_)
					if (wen | ren)
						mem_word <= mem_word == 128 / ram_bus_width ? 1 : mem_word + 1;
					else
						mem_word <= 1;
			end

			always @(posedge clk)
				if (!enable_)
					done_fetch <= mem_word == 128 / ram_bus_width;

			wire[5:0] word_1 = mem_word - 1;
			wire[7:0] curr_word = mem_word * ram_bus_width;

			always @(posedge clk)
				if (ren)
					mem_data[(128 - curr_word)+:ram_bus_width] <= ram_out;

			if (ram_data_width == 8)
				always @(*)
					ram_address <= ram_addr[31:4] * 16 + word_1 * (ram_bus_width >> 3);
			else if (ram_data_width == 16)
				always @(*)
					ram_address <= ram_addr[31:3] * 8 + word_1 * (ram_bus_width >> 4);
			else if (ram_data_width == 32)
				always @(*)
					ram_address <= ram_addr[31:2] * 4 + word_1 * (ram_bus_width >> 5);
			else if (ram_data_width == 64)
				always @(*)
					ram_address <= ram_addr[31:1] * 2 + word_1 * (ram_bus_width >> 6);
			else if (ram_data_width == 128)
				always @(*)
					ram_address <= ram_addr;
			else
				always @(*)
					ram_address <= 'hx;

			assign ram_in = ram_in_i[(128 - curr_word)+:ram_bus_width];
		end
	endgenerate

	assign device_write_enable = cpu_wen & access_device;
	assign device_read_enable = cpu_ren & access_device;
	assign device_address = access_device & (cpu_ren | cpu_wen) ? cpu_address : 0;
	assign device_input = access_device & (cpu_wen | cpu_ren) ? cpu_data_out : 0;

	wire cpu_wen, cpu_ren;
	wire[1:0] cpu_memsize;
	wire[31:0] cpu_address;
	wire[31:0] cpu_data_out;
	wire[31:0] cpu_data_in;
	wire cache_hit;
	wire n_cache_hit;
	wire[31:0] cache_out;

	wire[31:0] plic_out;
	wire plic_interrupt_out;
	wire[7:0] i_id;
	wire busy_plic;

	assign cpu_data_in =
		access_mtime ? mtime[(cpu_address == end_devs)+:32] : access_mtimecmp ? mtimecmp[(cpu_address == end_devs + 8)+:32] : access_plic ? plic_out : access_device ? device_output : cache_out;

	wire[19:0] interrupts;
	assign interrupts[0] = mtime_interrupt_enable;

	plic #(
		.n_external_gateways(16),
		.address_width($clog2(end_plic))
	) PLIC (
		.clk(clk),
		.enable_(enable_),
		.gateways({external_interrupts, mtime_interrupt_enable}),
		.cpu_out(cpu_data_out),
		.cpu_in(plic_out),
		.cpu_address(cpu_address[$clog2(end_plic) - 1:0]),
		.cpu_memsize(cpu_memsize),
		.cpu_write_enable(cpu_wen && access_plic),
		.cpu_read_enable(cpu_ren && access_plic),
		.interrupt_notify(plic_interrupt_out),
		.interrupt_id(i_id),
		.busy(busy_plic)
	);

	wire write_cache = cpu_ren && ~access_mtime && ~access_mtimecmp && ~access_device && ~access_plic;
	wire read_cache = cpu_wen && ~access_mtime && ~access_mtimecmp && ~access_device && ~access_plic;

	L1 cache(
		.clk(clk),
		.reset(reset),
		.read_enable(write_cache),
		.write_enable(read_cache),
		.memsize(cpu_memsize),
		.address(cpu_address),
		.din(cpu_data_out),
		.dout(cache_out),
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
		.starting_point(starting_point)
	) CPU(
		.clk(clk),
		.reset(reset),
		.enable_(enable_),
		.mem_out(cpu_data_in),
		.mem_in(cpu_data_out),
		.addr(cpu_address),
		.data_size(cpu_memsize),
		.mem_write_enable(cpu_wen),
		.mem_read_enable(cpu_ren),
		.mem_ready(cache_hit && !(access_mtime || access_mtimecmp || access_device || access_plic) || (access_mtime || access_mtimecmp || access_device || access_plic && ~busy_plic) && (cpu_wen || cpu_ren)),
		.interrupt_m(plic_interrupt_out),
		.interrupt_type_m(i_id != 1)
	);

	assign ram_write_enable = wen & ~access_device;
	assign ram_read_enable = ren  & ~access_device;

	initial begin
		if (ram_data_width > ram_bus_width) begin
			$display("Error: the data width is bigger than the bus width\n");
			$finish;
		end
	end

endmodule
