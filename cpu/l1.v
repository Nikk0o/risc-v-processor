`include "cpu/defines.vh"

/*
* 4-way set associative memory with
* 8 sets
*/
module L1(
	input clk,
	input reset,
	input read_enable,
	input write_enable,
	input[1:0] memsize,
	input[31:0] address,
	input[31:0] din,
	output reg[31:0] dout,

	input[127:0] ram_out,
	output reg[127:0] ram_in,
	output reg ram_ren,
	output reg ram_wen,
	output reg[31:0] ram_addr,

	input busy_l, // Value sent by the lower level to indicate that the data is fully loaded
	output reg busy
);

	reg[127:0] data[7:0][3:0];
	reg[26:0] block_tags[7:0][3:0];

	reg[2:0] state;

	wire[2:0] set = address[6:4];

	reg[1:0] line;
	reg found;

	reg[1:0] i;

	reg[2:0] next_insert[7:0];
	reg[7:0] full;

	reg[1:0] last;

	reg[127:0] ram_out_i;
	reg[127:0] in_i;

	reg[1:0] fifo[7:0][3:0];

	reg[1:0] fifo_3;
	reg[2:0] next_insert_;

	reg[1:0] l;
	reg[2:0] s;
	always @(posedge clk) begin
		if (reset) begin
			state <= `FETCH;
			for (s = 0; s < 8; s = s + 1) begin
				full[s] <= 0;
				for (l = 0; l < 4; l = l + 1)
					block_tags[s][l][1] <= 0;
			end
		end
		else
			case (state)
				`FETCH: begin
					for (l = 0; l < 4; l = l + 1)
						if (block_tags[set][l][26:2] == address[31:7] && block_tags[set][l][1]) begin
							line = l;
							found = 1'b1;
						end

					found <= 1'b0;

					if (read_enable | write_enable)
						if (found) begin
							busy <= 1'b1;
							state <= `HIT;
						end
						else begin
							busy <= 1'b1;
							ram_ren <= 1'b1;
							ram_addr <= address;
							state <= `MISS;
						end
				end
				`HIT: begin
					if (write_enable) begin
						in_i = data[set][line];
						case(memsize)
							`BYTE:
								in_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 8] = din[7:0];
							`HALF:
								in_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 15] = din[15:0];
							`WORD:
								in_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 32] = din;
						endcase

						data[set][line] <= in_i;
						block_tags[set][line][0] <= 1'b1;
					end

					if (read_enable) begin
						dout <= data[set][line][127 - (address[3:2] * 32):128 - address[3:2] * 32 - 32];
					end

					busy <= 1'b0;
					state <= `FETCH;
				end
				`MISS: begin
					if (full[set]) begin
						ram_ren <= 1'b0;
						state <= `REPLACE;
					end
					else if (!busy_l) begin
						next_insert_ = next_insert[set];

						next_insert[set] <= next_insert[set] + 1;
						full[set] <= next_insert[set] == 3;

						for (i = 0; i < 3; i = i + 1)
							fifo[set][i + 1] <= fifo[set][i];
						fifo[set][0] <= next_insert[set];

						ram_out_i = ram_out;

						if (read_enable)
							dout <= ram_out_i[127 - (address[3:2] * 32):128 - address[3:2] * 32 - 32];

						if (write_enable) begin
							case(memsize)
								`BYTE:
									ram_out_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 8] = din[7:0];
								`HALF:
									ram_out_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 16] = din[15:0];
								`WORD:
									ram_out_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 32] = din;
							endcase
							block_tags[set][next_insert_][0] <= 1'b1;
						end
						else
							block_tags[set][next_insert_][0] <= 1'b0;

						data[set][next_insert_] <= ram_out_i;
						block_tags[set][next_insert_][26:2] <= address[31:7];
						block_tags[set][next_insert_][1] <= 1'b1;

						ram_ren <= 1'b0;
						busy <= 1'b0;
						state <= `FETCH;
					end
				end
				`REPLACE: begin
					fifo_3 = fifo[set][3];

					for (i = 0; i < 3; i = i + 1)
						fifo[set][i + 1] <= fifo[set][i];
					fifo[set][0] <= fifo[set][3];

					ram_out_i = ram_out;

					if (block_tags[set][fifo_3][0]) begin
						ram_wen <= 1'b1;
						ram_addr <= address;
						ram_in <= data[set][fifo_3];

						state <= `WRITE_BACK;
					end
					else begin
						busy <= 1'b0;
						state <= `FETCH;
					end

					if (read_enable)
						dout <= ram_out_i[127 - (address[3:2] * 32):128 - address[3:2] * 32 - 32];

					if (write_enable) begin
						case(memsize)
							`BYTE:
								ram_out_i[127 - (address[3:0] * 8):128 - address[3:0] * 8 - 8] = din[7:0];
							`HALF:
								ram_out_i[127 - (address[3:1] * 8) + 15:128 - address[3:0] * 8 - 16] = din[15:0];
							`WORD:
								ram_out_i[127 - (address[3:2] * 8):128 - address[3:0] * 8 - 32] = din;
						endcase
						block_tags[set][fifo_3][0] <= 1'b1;
					end
					else
						block_tags[set][fifo_3][0] <= 1'b0;

					data[set][fifo_3] <= ram_out_i;
					block_tags[set][fifo_3][26:2] <= address[31:7];
					block_tags[set][fifo_3][1] <= 1'b1;
				end
				`WRITE_BACK: begin
					if (!busy_l) begin
						state <= `FETCH;
						busy <= 1'b0;
						ram_wen <= 1'b0;
					end
				end
			endcase
	end

	integer j, k;
	initial begin
		for (j = 0; j < 8; j = j + 1)
			for (k = 0; k < 4; k = k + 1) begin
				block_tags[j][k] = 0;
				data[j][k] = 0;
				next_insert[j] = 0;
			end
	end

endmodule
