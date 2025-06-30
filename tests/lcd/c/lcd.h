#ifndef LCD_H
#define LCD_H

typedef struct {
	char *en_addr;
	char *cmm_addr;
	char lineno;
	char font;
	char data_width;
} Display;

void init_lcd(Display *, char, char, char);

#endif
