#include "lcd.h"

static void _toggle_lcd(Display *d) {
	*(d->en_addr) |= 0b100;
	*(d->en_addr) &= 0b011;
}

static void _send_command(Display *d, char cmm, char rsrw) {

	*(d->cmm_addr) = cmm;
	*(d->en_addr) = rsrw;

	_toggle_lcd(d);

	if (d->data_width == 4) {
		cmm <<= 4;
		*(d->cmm_addr) = cmm;

		_toggle_lcd(d);
	}
}

void init_lcd(Display *d, char data_width, char lineno, char font) {
	if (!d)
		return;

	d->data_width = 8;

	for (int i = 0; i < 3; i++)
		_send_command(d, 0b00110000, 0b00);

	d->data_width = data_width;

	_send_command(d, 0b00110000 + (data_width << 3) + (font << 2), 0b00);
	_send_command(d, 0b00001000, 0b00);
	_send_command(d, 0b00000001, 0b00);
	_send_command(d, 0b00000100, 0b00);
}

void clear_screen(Display *d) {
	if (!d)
		return;

	_send_command(d, 0b00000001, 0b00);
}
