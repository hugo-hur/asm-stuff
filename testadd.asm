;Input:
;The registers RDI, RSI, RDX, RCX, R8, and R9 are used for integer and memory address arguments and
;XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6 and XMM7 are used for floating point arguments.
;
;For system calls, R10 is used instead of RCX.
;Additional arguments are passed on the stack and the return value is stored in RAX.
;
global test
test:
	;push edi
	;mov eax, rdi
	add rdi, 0x1
	mov rax, rdi
	ret
	;pop edi
	