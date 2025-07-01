INPUT(main.o)
ENTRY(init)
STARTUP(init.o)

OUTPUT("out.elf")

SECTIONS
{
	.text 0x0 :
	{
	}
}
