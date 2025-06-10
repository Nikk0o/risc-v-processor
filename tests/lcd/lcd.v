module lcd(input clk, output[9:0] lcd_data, output lcd_en);

	integer cnt = 0;
	reg clk_ = 0;
`ifdef FPGA
	always @(posedge clk)
		if (cnt == 1_000_000) begin
			clk_ <= ~clk_;
			cnt <= 0;
		end
		else
			cnt <= cnt + 1;
`endif

	reg[7:0] data_mem[31:0];
	reg[7:0] inst_mem[107:0];

	wire w_en;
	reg[31:0] i_mem_out = 0;
	wire[31:0] d_mem_in;
	wire[1:0] size;
	wire[31:0] d_addr;
	wire[31:0] addr;

	integer aua = 0;
`ifndef FPGA
	always begin
		#2;
		aua = aua + 1;
		clk_ <= ~clk_;
		if (aua == 1_000)
			$finish;
		$dumpvars(0, CPU, data_mem[0], data_mem[1], data_mem[2], data_mem[3], data_mem[4]);
	end
`endif

	always @(posedge clk_) begin
		if (w_en)
			if (size == 1)
				data_mem[d_addr] <= d_mem_in[7:0];
			else if (size == 2) begin
				data_mem[d_addr] <= d_mem_in[15:8];
				data_mem[d_addr + 1] <= d_mem_in[7:0];
			end
			else if (size == 3) begin
				data_mem[d_addr] <= d_mem_in[31:24];
				data_mem[d_addr + 1] <= d_mem_in[23:16];
				data_mem[d_addr + 2] <= d_mem_in[15:8];
				data_mem[d_addr + 3] <= d_mem_in[7:0];
			end

		i_mem_out <= {inst_mem[addr], inst_mem[addr + 1], inst_mem[addr + 2], inst_mem[addr + 3]};
	end

	cpu CPU(.clk(clk_), .d_mem_in(d_mem_in), .d_mem_out(), .i_mem_out(i_mem_out), .reset(1'b0), .write_data_size(size), .d_mem_wen(w_en), .d_addr(d_addr), .addr(addr));

	assign lcd_data = {data_mem[1][1:0], data_mem[0]};
	assign lcd_en = data_mem[4][0];

	initial begin
		$dumpfile("tmp/a.vcd");
		$readmemh("tests/lcd/mem.hex", inst_mem, 0, 107);
	end

endmodule
