all:
	yosys -p "read_verilog cpu/*.v; synth_gowin -json nikorv.json";
	nextpnr-himbaechel --json nikorv.json \
                   --write pnrnikorv.json \
                   --device GW1NR-LV9QN88PC6/I5 \
                   --vopt family=GW1N-9C \
                   --vopt cst=nikorv.cst
	gowin_pack -d GW1N-9C -o pack.fs pnrnikorv.json

clean:
	rm *.json
