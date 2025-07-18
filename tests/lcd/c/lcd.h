#pragma once

typedef struct lcd_ Display;
struct lcd_ {
	unsigned int *ioloc;
	int data_width;
	int lineno;
	int font;
	int cx;
	int cy;
};

int init_lcd(Display *d, int data_width, int lineno, int font);
