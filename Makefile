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

csr.sim:
	yosys -p "read_verilog cpu/*.v tests/csr/csr.v; hierarchy -top csr; proc; sim -clock clk -n 500 -vcd tmp/a.vcd"
	gtkwave tmp/a.vcd

lcd.sim:
	iverilog -s lcd cpu/*.v tests/lcd/lcd.v -o tmp/a.vvp
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

lcd.load:
	yosys -p "verilog_defines -DYOSYS=0; read_verilog cpu/*.v tests/lcd/lcd.v; hierarchy -top lcd; synth_gowin -json tmp/lcd.json"
	nextpnr-himbaechel --json tmp/lcd.json \
                   --write tmp/pnrlcd.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt family=GW1N-9C \
                   --vopt cst=tests/lcd/lcd.cst
	gowin_pack -d GW1N-9C -o tmp/pack.fs tmp/pnrlcd.json
	openFPGALoader -b tangnano9k tmp/pack.fs

vga.sim:
	iverilog -s vga cpu/*.v tests/vga/vga.v -o tmp/a.vvp
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

hdmi.sim:
	yosys -p "read_verilog tests/hdmi/*.v cpu/*.v; hierarchy -top tb; proc; sim -clock clk -n 500 -vcd tmp/a.vcd"
	gtkwave tmp/a.vcd

hdmi.load:
	yosys -p "read_verilog tests/hdmi/*.v; hierarchy -top hdmi; synth_gowin -json tmp/hdmi.json"
	nextpnr-himbaechel --json tmp/hdmi.json \
                   --write tmp/pnrhdmi.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt family=GW1N-9C \
                   --vopt cst=tests/hdmi/hdmi.cst
	gowin_pack -d GW1N-9C -o tmp/pack.fs tmp/pnrhdmi.json
	openFPGALoader -b tangnano9k tmp/pack.fs
