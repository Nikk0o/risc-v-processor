cpu.check:
	iverilog -s cpu cpu/*.v -o tmp/a.vvp -DRV32M=0

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

lcd.sim:
	iverilog -s lcd cpu/*.v tests/lcd/lcd.v -o tmp/a.vvp -DRV32M=0
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

lcd.load:
	yosys -p "verilog_defines -DYOSYS=0; read_verilog cpu/*.v tests/lcd/lcd.v; hierarchy -top lcd; synth_gowin -json tmp/lcd.json"
