#include "ecall.h"
#include "lcd.h"

int main(void) {
	Display *d = (Display *) 132;
	d->en_addr = (char *) 260;
	d->cmm_addr = (char *) 261;

	invoke_ecall(1, (long) d, 8, 1, 1);
	return 0;
}
