all: json pnr pack
	openFPGALoader -b tangnano9k pack.fs

pnr:
	nextpnr-himbaechel --json nikorv.json \
                   --write pnrnikorv.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt cst=nikorv.cst \
				   --vopt family=GW1N-9C

json:
	yosys -p "read_verilog cpu/*.v test.v; hierarchy -top top; synth_gowin -json nikorv.json"

pack:
	gowin_pack -d GW1N-9C -o pack.fs pnrnikorv.json

test.show:
	yosys -p "read_verilog cpu/*.v test.v; hierarchy -top top; synth_gowin; show"
