static int fatorial(int n, int i, int f) {
	if (i >= n)
		return f * i;

	return fatorial(n, i + 1, f * i);
}

int main(void) {
	int n = *((int *) 124);
	*((int *) 124) = fatorial(n, 1, 1);
	volatile int l = 1;
	while(l != 0);

	return 0;
}
