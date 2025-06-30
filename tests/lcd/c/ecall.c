void invoke_ecall(unsigned long arg0,
				  unsigned long arg1,
				  unsigned long arg2,
				  unsigned long arg3,
				  unsigned long arg4) {
	asm volatile(
		"ecall"
		: "+r" (arg0), "+r" (arg1), "+r" (arg2), "+r" (arg3), "+r" (arg4));
}
