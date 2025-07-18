`include "cpu/defines.vh"

/*
* 4-way set associative memory with
* 8 sets. Each line of the set has 4
* 4-byte words.
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

	input busy_l,
	output reg busy
);

	localparam set_width = 3;
	localparam num_sets = 1 << set_width;

	reg[127:0] data[num_sets - 1:0][3:0];
	reg[27 - set_width:0] block_tags[num_sets - 1:0][3:0];
	reg valid[num_sets - 1:0][3:0];
	reg modified[num_sets - 1:0][3:0];

	reg[2:0] state;

	wire[set_width - 1:0] set = address[3 + set_width:4];
	wire[27 - set_width:0] tag = address[31:4 + set_width];

	reg[1:0] line;
	reg found;

	reg[2:0] next_insert[num_sets - 1:0];
	reg[num_sets - 1:0] full;

	reg[1:0] fifo[num_sets - 1:0][3:0];

	// Intermediate registers used to store
	// the output of memories.
	// This ensures that the synthesis software won't
	// replace RAM with registers.
	reg[127:0] data_i;
	reg[127:0] in_i;
	reg[1:0] fifo_3;
	reg[2:0] next_insert_;
	wire[7:0] address_8 = {address[3:0], 3'b000};
	wire[7:0] address_32 = {address[3:2], 5'b00000};

	// Counters for for-loops
	reg[2:0] i;
	reg[2:0] l;
	reg[set_width:0] s;

	reg[1:0] where;

	always @(posedge clk) begin
		if (reset) begin
			state <= `FETCH;
			full <= 0;
			for (s = 0; s < num_sets; s = s + 1) begin
				valid[s][0] <= 0;
				valid[s][1] <= 0;
				valid[s][2] <= 0;
				valid[s][3] <= 0;
			end
		end
		else
			case (state)
				`FETCH: begin
					for (l = 0; l < 4; l = l + 1)
						if (&(block_tags[set][l] ~^ tag) && valid[set][l]) begin
							line = l;
							found = 1'b1;
						end

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
					else
						busy <= 1'b0;

					found = 0;
				end
				`HIT: begin
					busy <= 1'b0;
					state <= `FETCH;
				end
				`MISS: begin
					if (!busy_l && full[set]) begin
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

						block_tags[set][next_insert_] <= tag;
						valid[set][next_insert_] <= 1'b1;

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

					if (modified[set][fifo_3]) begin
						ram_wen <= 1'b1;
						ram_addr <= {block_tags[set][fifo_3], set, 4'b0000};
						ram_in <= data[set][fifo_3];

						state <= `WRITE_BACK;
					end
					else begin
						busy <= 1'b0;
						state <= `FETCH;
					end

					block_tags[set][fifo_3] <= tag;
					valid[set][fifo_3] <= 1'b1;
				end
				`WRITE_BACK: begin
					if (!busy_l) begin
						state <= `FETCH;
						busy <= 1'b0;
						ram_wen <= 1'b0;
					end
				end
			endcase

		if (state == `HIT)
			where = line;
		else if (state == `MISS)
			where = next_insert_[1:0];
		else if (state == `REPLACE)
			where = fifo_3;

		if (state == `HIT)
			data_i = data[set][where];
		else
			data_i = ram_out;

		if (state == `MISS && !busy_l && !full[set] || state == `REPLACE || state == `HIT) begin

			if (read_enable)
				dout <= data_i[(96 - address_32)+:32];

			if (write_enable) begin
				case(memsize)
					`BYTE:
						data_i[(120 - address_8)+:8] = din[31:24];
					`HALF:
						data_i[(112 - address_8)+:16] = din[31:16];
					`WORD:
						data_i[(96 - address_8)+:32] = din;
				endcase
				modified[set][where] <= 1'b1;
			end
			else if (state != `HIT)
				modified[set][where] <= 1'b0;

			if (state == `HIT && write_enable || state == `REPLACE || state == `MISS && !busy_l && !full[set])
				data[set][where] <= data_i;
		end
	end

	integer j, k;
	initial begin
		for (j = 0; j < num_sets; j = j + 1) begin
			for (k = 0; k < 4; k = k + 1)
				valid[j][k] = 0;
			next_insert[j] = 0;
		end
	end

endmodule
