`include "cpu/defines.vh"

module plic(
	input clk,
	input enable_,
	input[n_gateways - 1:0] gateways,

	input[31:0] cpu_out,
	input[address_width - 1:0] cpu_address,
	input[1:0] cpu_memsize,
	input cpu_write_enable,
	input cpu_read_enable,

	output reg[31:0] cpu_in,

	output interrupt_notify,
	output[7:0] interrupt_id,

	output reg busy
);

	parameter n_external_gateways = 16;
	parameter address_width = 32;
	localparam n_gateways = n_external_gateways + 1 /*mtime*/;

	wire[7:0] priorities[n_gateways + 1:0];
	wire[7:0] enable_gateway[n_gateways - 1:0];
	wire[7:0] claim;

	reg[n_gateways - 1:0] pending;

	wire[7:0] priority_threshold;
	reg[7:0] mem[(n_gateways + 1) * 2 + 4:0];

	reg[2:0] word_byte;
	reg done_get;
	reg done_write;
	reg[31:0] word;

	reg[1:0] mem_state;
	reg write_back;

	always @(negedge clk) begin
		if (!enable_)
			case(mem_state)
				'd0: begin
					busy <= 1;

					if (cpu_read_enable && busy) begin
						mem_state <= 'd1;
						write_back <= 0;
					end
					else if (cpu_write_enable && busy) begin
						mem_state <= 'd1;
						write_back <= 1;
					end

					mem[(n_gateways + 1) * 2] <= 0;
				end
				'h1: begin
					if (!done_get) begin
						word_byte <= word_byte + 1;
						done_get <= word_byte == 3;

						word[31 - word_byte*8-:8] <= mem[{cpu_address[address_width - 1:2], 2'b00} + word_byte];
					end
					else if (write_back) begin
						mem_state <= 2;
						word_byte <= 0;
						done_get <= 0;

						if (cpu_write_enable)
							case(cpu_memsize)
								`BYTE:
									word[31 - {cpu_address[1:0], 3'b000}-:8] <= cpu_out[31:24];
								`HALF:
									word[31 - {cpu_address[1], 4'h0}-:16] <= cpu_out[31:16];
								`WORD:
									word <= cpu_out;
							endcase
					end
					else begin
						busy <= 0;
						mem_state <= 0;
						done_get <= 0;
						word_byte <= 0;

						cpu_in <= word;
						word <=	0;
					end
				end
				'h2: begin
					if (!done_write) begin
						word_byte <= word_byte + 1;
						done_write <= word_byte == 3;

						mem[{cpu_address[address_width - 1:2], 2'b00} + word_byte] <= word[31 - word_byte*8-:8];
					end
					else begin
						busy <= 0;
						mem_state <= 0;
						done_write <= 0;
						word_byte <= 0;
						word <= 0;
					end
				end
			endcase
	end

	genvar j;
	generate
		for (j = 0; j < n_gateways; j = j + 1) begin
			assign priorities[j] = mem[(j + 1) * 2];
			assign enable_gateway[j] = mem[(j + 1) * 2 + 1];
		end
	endgenerate

	assign claim = mem[(n_gateways + 1) * 2];
	assign priority_threshold = mem[(n_gateways + 1) * 2 + 1];

	integer i;
	reg[7:0] _priority;
	reg[7:0] id;
	reg[7:0] highest_priority;
	reg[7:0] highest_id;

	always @(*) begin
		_priority = 0;
		id = 0;

		for (i = 0; i < n_gateways; i = i + 1)
			if (priorities[i] > _priority && gateways[i] && |enable_gateway[i] && ~pending[i]) begin
				_priority = priorities[i];
				id = i + 1;
			end

		highest_priority <= _priority;
		highest_id <= id;
	end

	reg[7:0] ip_priority;
	reg ip_enable;
	reg[7:0] ip_id;

	reg[7:0] last_id;

	always @(posedge clk) begin
		if (claim) begin
			if (ip_enable) begin
				ip_enable <= 1'b0;
				ip_priority <= 1'b0;
				ip_id <= 0;
				pending[ip_id] <= 1'b0;
			end

			last_id <= ip_id;
		end
		else if (highest_priority > priority_threshold && ~ip_enable) begin
			ip_priority <= highest_priority;
			ip_enable <= 1'b1;
			ip_id <= highest_id;
			pending[highest_id] <= 1'b1;
		end
	end

	assign interrupt_id = ip_id;
	assign interrupt_notify = ip_enable;

endmodule
