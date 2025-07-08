cpu.check:
	yosys -p "verilog_defines -DRV32M; read_verilog cpu/*.v"

fatorial.sim:
	yosys -p "verilog_defines -DRV32M; read_verilog cpu/*.v tests/fatorial/fatorial.v; hierarchy -top fatorial; proc; sim -vcd tmp/a.vcd -n 500 -clock clk -zinit" -q
	gtkwave tmp/a.vcd
