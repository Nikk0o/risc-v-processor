#include "lcd.h"

static void toggle_lcd(Display *d) {
	*d->ioloc |= 0b10000000000;
	*d->ioloc &= 0b01111111111;
}

void send_command(Display *d, unsigned char cmm, unsigned char rsrw) {
	*d->ioloc = cmm + (((unsigned int) rsrw) << 9);

	toggle_lcd(d);

	if (d->data_width == 4) {
		cmm <<= 4;
		*d->ioloc = cmm + (((unsigned int) rsrw) << 9);

		toggle_lcd(d);
	}

	if (cmm == 0x1 || cmm == 0x2) {
		__asm__("ecall\n");
		__asm__("wfi\n");
	}
}

int init_lcd(Display *d, int data_width, int lineno, int font) {
	if (!d || data_width != 4 && data_width != 8 || lineno < 1 || lineno > 2 || font != 0 && font != 1)
		return 1;

	d->data_width = 8;
	for (int i = 0; i < 3; i = i + 1)
		send_command(d, 0b00110000, 0b00);

	d->data_width = data_width;
	d->lineno = lineno;
	d->font = font;
	d->cx = 0;
	d->cy = 0;

	send_command(d, 0b00100000 + ((d->data_width == 8) << 4), 0b00);
	send_command(d, 0b00100000 + ((d->data_width == 8) << 4) + ((lineno == 2) << 3) + (font << 2), 0b00);
	send_command(d, 0b00001000, 0b00);
	send_command(d, 0b00000001, 0b00);
	send_command(d, 0b00000110, 0b00);

	return 0;
}
