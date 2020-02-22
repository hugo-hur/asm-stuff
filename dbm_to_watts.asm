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
section .data
	ten: dd 10
	formatStrdec: db `The int is %d\n`,0 ;'Number is %d\n',0
	formatStrf: db `The int is %f\n`,0 ;'Number is %d\n',0
	
section .text
extern printf
printfcallfloat:;Pass in RDI
	;PUSHA
	MOV RSI, RDI
	;PUSH RDI
	MOV RDI, formatStrf
	;MOV RSI,
	MOV AL, 0 
	call printf
	ret

printfcall:;Pass in RDI
	;PUSHA
	MOV RSI, RDI
	;PUSH RDI
	MOV RDI, formatStrdec
	;MOV RSI,
	MOV AL, 0 
	call printf
	ret


global dbmwatts
dbmwatts: ;(returns floating point watt value, input is watt value in dBm)
	;xmm0;Input here
	;sub esp, 8 ;Make space on the stack for temporarily store the constant float
	SUB RSP, 8
	MOV DWORD [RSP], __float32__(10.0);Store the exponent divider to the stack
	CVTSS2SD XMM1, [RSP]    ; Load 32-bit single and convert it to 64-bit double. Store in XMM1
	DIVSD XMM0, XMM1 ;Divide the input by 10, store result to xmm0

	CVTSD2SI RDI, XMM0 ;truncate the value
	call printfcall

	;Calculate 10^xmm0
	;Move the last result to x87 stack
	MOVSD QWORD [RSP], XMM0 ;Copy result back to the stack
	
	;Clean the fpu stack top
	FSTP
	FSTP

	FLD QWORD [RSP] ;Load the previous result to the x87 stack ST(1)
	
	;Load 10 to the fpu stack
	MOV RAX, 10
	PUSH RAX
	FLD QWORD [RSP] ;ST(0)
	POP RAX

	;Do the math y = xmm0, x=10 X*LOG2(Y)
	FYL2X ;ST(1) = OUT
	;Calculate 2^ST(1)
	
	FSTP ;just remove ST(0), no need to preserve
	;We now have the result of x*log2(y) in ST(0), calculate 2^ST(0)
	;calculate 2 to the power of the whole part of exponent
	;Get the whole part of the exponent
	;load the result from the stack to the xmm0 reg
	FSTP QWORD [RSP];Pop the result from the logarithm to the stack
	MOV RDI, QWORD [RSP]
	call printfcallfloat

	MOVSD XMM0, QWORD [RSP]
	;these are temp
	ADD RSP, 8
	RET

	;Before truncating save the result to another xmm reg
	MOVSD XMM1, QWORD [RSP]
	;dest, source
	;CVTSD2SI XMM0, XMM1 ;truncate the value (result of the logarithm from the stack) and store to xmm0
	
	MOVSD QWORD [RSP], XMM0 ;Copy the value to the stack
	MOV RDI, QWORD [RSP];Pass in RDI register
	CALL twotopwr ;Ret val in RAX
	
	;Subtract the XMM0 from XMM1
	SUBSD XMM1, XMM0
	;Calculate 2^XMM1
	MOVSD QWORD [RSP], XMM1 ;Copy the remainder back to the stack
	FLD QWORD [RSP];Load the remainder to the fpu stack ST(0)
	F2XM1 ; ST(0) = 2^ST(0) - 1
	;Pop th resutl back to cpu stack
	FSTP QWORD [RSP]
	;load back to sse (floating point)
	MOVSD XMM0, QWORD [RSP]
	;Add one to the result
	;ADDSS XMM0, 1;Must be reg?
	;Multiply with the whole number we got from the exponentiation subroutine
	;Load the rax to sse (whole number in rax)
	SUB RSP, 4
	MOV DWORD [RSP], EAX
	MOVD XMM1, DWORD [RSP]
	ADD RSP, 4

	MULSD XMM0, XMM1 ;Result in XMM0

	;FLD RAX;Load to the fpu stack from RAX, now we have exponentiated
	
	;SUBSD

	add rsp, 8;Reset the stack
	ret

twotopwr:
	;RDI contains the power
	MOV EAX, 2;The 2 here
	CMP RDI, 0;If 0 then return 1
	JE ret1
	
loop:
	DEC RDI;Subtracxt the exponent
	CMP RDI, 0;Check if 0
	JE ret;if 0 then return the value in rax
	MUL EAX;Multiplies eax with the value here
	JMP loop ;Again
ret1:
	MOV EAX, 1;Exponent was 0
ret:
	;MOV RAX, RDX;return value to rax
	RET
