;Input:
;The registers RDI, RSI, RDX, RCX, R8, and R9 are used for integer and memory address arguments and
;XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6 and XMM7 are used for floating point arguments.
;
;For system calls, R10 is used instead of RCX.
;Additional arguments are passed on the stack and the return value is stored in RAX.
;Floating point return values are returned in XMM0.
;
;dBm to watts
;P(W) = 1W * 10exp(P(dBm) / 10) / 1000
global dbmwatts
dbmwatts: ;(returns floating point watt value, input is watt value in dBm)
	;xmm0;Input here
	;sub esp, 8 ;Make space on the stack for temporarily store the constant float
	sub rsp, 8
	mov dword [rsp], __float32__(10.0);Store the exponent divider to the stack
	cvtss2sd xmm1, [rsp]    ; Load 32-bit single and convert it to 64-bit double. Store in XMM1
	divsd xmm0, xmm1 ;Divide the input by 10, store result to xmm0
	;Calculate 10^xmm0
	add rsp, 8;Reset the stack
	ret