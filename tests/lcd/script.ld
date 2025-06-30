INPUT(trap.o ecall.o lcd.o main.o)
STARTUP(init.o)
ENTRY(init)

OUTPUT("out.elf")

SECTIONS
{
	.text 0x0 :
	{
	}
}
