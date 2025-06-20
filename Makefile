fatorial.sim:
	iverilog -s fatorial cpu/*.v tests/fatorial/fatorial.v -o tmp/a.vvp -DRV32M=0
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

fatorial.check:
	iverilog -s fatorial cpu/*.v tests/fatorial/fatorial.v -o tmp/a.vvp -DRV32M=0

csr.sim:
	iverilog -s csr cpu/*.v tests/csr/csr.v -o tmp/a.vvp -DRV32M=0
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

exception.sim:
	iverilog -s excep cpu/*.v tests/excep/excep.v -o tmp/a.vvp -DRV32M=0
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

exception.check:
	iverilog -s excep cpu/*.v tests/excep/excep.v -o tmp/a.vvp -DRV32M=0
