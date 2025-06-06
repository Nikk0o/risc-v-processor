module vga(input clk, output[2:0] rgb, output hs, output vs);

	// VGA timings

	reg[9:0] cx = 0, cy = 0;

	alwys @(posedge vga_clk) begin
		cx <= cx == 839 ? 0 : cx + 1;
		cy <= cx == 839 ? cy == 500 ? 0 : cy + 1 : cy;
	end

	assign hs = cx >= 640 + 16 && cx < 640 + 16 + 64;
	assign vs = cy >= 480 + 1 && cy < 480 + 1 + 3;

	// CPU logic
	
	reg[7:0] inst_mem[];
	reg[7:0] data_mem[];

	wire[31:0] d_mem_in;
	reg[31:0] i_mem_out = 0;
	reg[31:0] d_mem_out = 0;

	cpu CPU(.clk(clk2))
endmodule
