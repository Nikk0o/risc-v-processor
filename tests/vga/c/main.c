void next_color(unsigned char *framebuf) {
	unsigned char r = framebuf[0];
	unsigned char g = framebuf[1];
	unsigned char b = framebuf[2];

	r += 1;

	if (r == 128)
		g += 1;

	if (g == 128)
		b += 1;

	framebuf[0] = r;
	framebuf[1] = g;
	framebuf[2] = b;
}

int main(void) {

	char done = 0;
	unsigned char *c = (unsigned char *) 1;

	while (1) {
		if (*c) {
			if (!done) {
				done = 1;
				next_color((unsigned char *) 3);
			}
		}
		else
			done = 0;
	}

	return 0;
}
