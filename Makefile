cpu.check:
	yosys -p "verilog_defines -DRV32M; read_verilog -sv cpu/*.v; hierarchy -top NK0W0; prep; scc"

%.load: %.json %.pnr %.pack
	openFPGALoader -b tangnano9k tmp/pack.fs

%.sim:
	yosys -p "verilog_defines -DRV32M; read_verilog cpu/*.v tests/$*/*.v; hierarchy -top $*; proc; sim -vcd tmp/a.vcd -clock clk -zinit -n 10000"
	gtkwave tmp/a.vcd
