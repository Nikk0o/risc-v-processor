`timescale 1ns/100ps

module tb;

	reg clk = 1;
	integer cnt = 0;

	reg[7:0] mem[31:0];
	reg[7:0] d_mem[31:0];
	wire[31:0] addr, d_addr, d_mem_in;
	reg[31:0] i_mem_out = 0, d_mem_out = 0;
	wire[1:0] w_size;
	wire enable_write;

	reg reset = 1;


	integer j;
	always begin
		#2;
		clk <= ~clk;

		if (cnt == 999)
			$finish;

		if (clk)
			cnt <= cnt + 1;

		$dumpvars(0, d_mem[0], CPU, i_mem_out, reset, addr, d_mem[1], d_mem[2], d_mem[3]);
		for (j = 0; j < 32; j = j + 1)
			$dumpvars(0, CPU.regs.regs[j]);
	end

	always @(posedge clk) begin
		i_mem_out <= {addr > 31 ? 8'b0 : mem[addr], addr > 30 ? 8'b0 : mem[addr + 1], addr > 29 ? 8'b0 : mem[addr + 2], addr > 28 ? 8'b0 : mem[addr + 3]};
		d_mem_out <= d_mem[d_addr];

		if (enable_write)
			if (w_size == 3) begin
				d_mem[d_addr] <= d_mem_in[31:24];
				d_mem[d_addr + 1] <= d_mem_in[23:16];
				d_mem[d_addr + 2] <= d_mem_in[15:8];
				d_mem[d_addr + 3] <= d_mem_in[7:0];
			end
			else if (w_size == 2) begin
				d_mem[d_addr] <= d_mem_in[15:8];
				d_mem[d_addr + 1] <= d_mem_in[7:0];
			end
			else if (w_size == 1)
				d_mem[d_addr] <= d_mem_in[7:0];

		reset <= 0;
	end

	cpu CPU(.clk(clk), .i_mem_out(i_mem_out), .d_mem_out(d_mem_out), .d_mem_in(d_mem_in), .reset(reset), .write_data_size(w_size), .d_mem_wen(enable_write), .addr(addr), .d_addr(d_addr));

	integer i;
	initial begin
		$dumpfile("tmp/a.vcd");
		$readmemh("tests/factorial/mem.hex", mem);
		for (i = 0; i < 32; i = i + 1)
			d_mem[i] <= (2 ** i) ** i;
	end

endmodule
