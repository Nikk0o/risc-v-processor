INPUT(main.o)
STARTUP(setup.o)
OUTPUT(a.out)

__end_stack = 1024;

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
