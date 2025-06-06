all:

test.factorial:
	iverilog tests/factorial/tb.v cpu/* -s tb -o a.vvp
	mv a.vvp tmp/
	vvp tmp/a.vvp
	gtkwave tmp/a.vcd
