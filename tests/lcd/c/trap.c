#include "trap.h"

#define read_csr(csr, a) __asm__("csrrs %0, " #csr ", zero" : "=r" (a))
#define write_csr(csr, a) __asm__("csrrw zero, " #csr ", %0" : : "r" (a))

extern unsigned int delay;
extern unsigned long long *mtimecmp;
extern unsigned long long *mtime;

void handle_trap()
{
	unsigned int cause;
	unsigned int mepc;
	read_csr(mcause, cause);
	__asm__("csrrs %0, mepc, zero\n" : "=r" (mepc));

	if (cause == 0x8000000d)
	{
		*mtimecmp = -1;
	}
	else if (cause == 8 || cause == 9 || cause == 11)
	{
		unsigned long long mt;
		*mtime = 0;
		__asm__(
			"sw zero, 0(%0)\n\tsw %1, 4(%0)" : : "r" (mtimecmp), "r" (delay)
		);
	}

	*((unsigned char *) 36) = 1;
	__asm__("csrrw zero, mepc, %0\n" : : "r" (mepc));
}
