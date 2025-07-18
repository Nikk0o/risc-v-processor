INPUT(main.o lcd.o trap.o)
STARTUP(setup.o)
OUTPUT(a.out)

__end_stack = 2048;
plic_1 = 2;

SECTIONS
{
	.text 312 :
	{
		*(.text)
	}

	.data (ADDR(.text) + SIZEOF(.text)) :
	{
		*(.data)
	}
}
