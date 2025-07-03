#include "lcd.h"

unsigned long freq = 27000;

static void sleep(unsigned long ms) {
	volatile int c = 0;
	while (c < ms * freq)
		c += 1;
}

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

	if (cmm == 0b00000001 || cmm == 0b00000010)
		sleep(4);
}

void init_lcd(Display *d, char data_width, char lineno, char font) {
	if (!d)
		return;

	d->data_width = 8;

	for (int i = 0; i < 3; i++)
		_send_command(d, 0b00110000, 0b00);

	d->data_width = data_width;

	_send_command(d, 0b00110000 + ((data_width == 8) << 3) + (font << 2), 0b00);
	_send_command(d, 0b00001000, 0b00);
	_send_command(d, 0b00000001, 0b00);
	_send_command(d, 0b00000100, 0b00);
}

void clear_screen(Display *d) {
	if (!d)
		return;

	_send_command(d, 0b00000001, 0b00);
}

void set_ddram_address(Display *d, char cx, char cy) {
	if (!d || cx > 16 || cy > 2 || cy < 0 || cx < 0)
		return;

	_send_command(d, 0b10000000 + (cy - 1 ? 0x40 + cx : cx), 0b00);
}
