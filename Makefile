all:

synthtest:
	yosys -p "read_verilog cpu/*; hierarchy -top cpu; synth"

shownetlist:
	yosys -p "read_verilog cpu/*; hierarchy -top cpu; synth; flatten; show cpu"

factorial.test:
	iverilog tests/factorial/tb.v cpu/* -s tb -o a.vvp
	mv a.vvp tmp/
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

vga.load:
	yosys -p "verilog_defines -DFPGA; read_verilog cpu/*.v tests/vga/vga.v; synth_gowin -json tmp/vga.json"
	nextpnr-himbaechel --json tmp/vga.json \
                   --write tmp/pnrvga.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt family=GW1N-9C \
                   --vopt cst=tests/vga/vga.cst
	gowin_pack -d GW1N-9C -o tmp/pack.fs tmp/pnrvga.json
	openFPGALoader -b tangnano9k tmp/pack.fs

vga.test:
	iverilog tests/vga/vga.v cpu/* -s vga -o a.vvp
	mv a.vvp tmp/
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

vga.show:
	yosys -p "verilog_defines -DYOSYS -DFPGA; read_verilog cpu/*.v tests/vga/vga.v; hierarchy -top vga; synth_gowin; show"

lcd.test:
	iverilog tests/lcd/lcd.v cpu/* -s lcd -o a.vvp
	mv a.vvp tmp/
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd

lcd.load:
	yosys -p "verilog_defines -DFPGA; read_verilog cpu/*.v tests/lcd/lcd.v; synth_gowin -json tmp/lcd.json"
	nextpnr-himbaechel --json tmp/lcd.json \
                   --write tmp/pnrlcd.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt family=GW1N-9C \
                   --vopt cst=tests/lcd/lcd.cst
	gowin_pack -d GW1N-9C -o tmp/pack.fs tmp/pnrlcd.json
	openFPGALoader -b tangnano9k tmp/pack.fs

clean:
	rm tmp/*
