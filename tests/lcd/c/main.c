#include "lcd.h"

Display d __attribute__ ((section("data")));
int ioloc __attribute__ ((section("data"))) = 40;

unsigned long long *mtime = (unsigned long long *) 296;
unsigned long long *mtimecmp = (unsigned long long *) 304;
unsigned int delay = 200;

int main() {
	d = (Display) {.ioloc = (unsigned int *) ioloc};
	init_lcd(&d, 8, 2, 1);

	int i = 0;
	while(i == 0);

	return 0;
}
