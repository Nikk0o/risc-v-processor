
int d __attribute__ ((section("data"))) = 5;

int n_addr;

int fatorial(int n, int f, int i) {
	if (i >= n)
		return f * i;
	return fatorial(n, f * i, i + 1);
}

int main(void) {
	int n = d;
	*(&d) = fatorial(n, 1, 1);

	int i = 0;
	while(i == 0);

	return 0;
}
