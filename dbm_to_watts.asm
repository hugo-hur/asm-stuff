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
	formatStrf: db `The int is %f\n`,0 ;'Number is %f\n',0
	
section .text
extern printf

%macro pushxmm 1
	SUB RSP, 8;Move the stack
	MOVSD QWORD [RSP], %1
%endmacro
%macro popxmm 1
	MOVSD %1 , QWORD [RSP]
	ADD RSP, 8;Move the stack
%endmacro

printfcallfloat:
	;Value is passed here in RDI
	PUSH RDI ;Preserve value of rdi
	PUSH RAX ;Preserve value of RAX
	pushxmm XMM0 ;Preserve XMM0
	pushxmm XMM1 ;Added this to make sure XMM1 is surely preserved after call
	;Double is passed to printf in XMM0
	;Now we move the value from the reg to the XMM0 using stack
	PUSH RDI
	popxmm XMM0
	MOV AL, 1;We are passing one argument so al should be 1
	MOV RDI, formatStrf ;Format string is passed in RDI
	
	CALL printf ;Does not necessarily preserve SSE registers
	
	;Restore XMM regs
	popxmm XMM1 ;Pop it
	popxmm XMM0
	POP RAX
	POP RDI
	RET

printfcall:;Pass in RDI
	
	PUSH RSI
	MOV RSI, RDI
	PUSH RDI
	PUSH RAX
	pushxmm XMM0
	pushxmm XMM1 ;Added this to make sure XMM1 is surely 

	MOV RDI, formatStrdec
	MOV AL, 0 
	CALL printf

	popxmm XMM1
	popxmm XMM0
	POP RAX
	POP RDI
	POP RSI
	RET

addone: 
	;Preserve XMM1
	pushxmm XMM1

	SUB RSP, 8 ;Move the stack pointer to store the constant temporarily
	MOV DWORD [RSP], __float32__(1.0);Store the constant to the stack
	CVTSS2SD XMM1, [RSP]    ; Load 32-bit single and convert it to 64-bit double. Store in XMM1
	ADDSS XMM0, XMM1;add the one

	ADD RSP, 8 ;Restore the stack
	;Load the XMM1 back
	popxmm XMM1
	RET

global dbmwatts
dbmwatts: ;(returns floating point watt value, input is watt value in dBm)
	;Align the stack
	SUB RSP, 8 ;8 bytes return address
	;xmm0;Input here
	;sub esp, 8 ;Make space on the stack for temporarily store the constant float
	SUB RSP, 8
	MOV DWORD [RSP], __float32__(10.0);Store the exponent divider to the stack
	CVTSS2SD XMM1, [RSP]    ; Load 32-bit single and convert it to 64-bit double. Store in XMM1
	DIVSD XMM0, XMM1 ;Divide the input by 10, store result to xmm0
	;Print xmm1
	MOVSD QWORD [RSP], XMM1 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat

	;Calculate 10^xmm0
	;Load 10 to the fpu stack
	PUSH 10
	FILD QWORD [RSP]
	POP RDI

	MOVSD QWORD [RSP], XMM0 ;Copy to stack
	FLD QWORD [RSP];Load number float from XMM0 to the x87
	;Do the math y = xmm0 (2), x=10 X*LOG2(Y)
	FYL2X
	;We now have the result of x*log2(y) in ST(0), calculate 2^ST(0)
	;calculate 2 to the power of the whole part of exponent
	;Get the whole part of the exponent
	;load the result from the stack to the xmm0 reg
	FSTP QWORD [RSP];Pop the result from the logarithm to the stack
	MOVSD XMM0, QWORD [RSP];Move the result back to xmm0
	CVTSD2SI RDI, XMM0 ;truncate the value (result of the logarithm from the stack) and store to RDI
	
	CALL twotopwr ;Calculate 2^whole exponent
	MOV RDI, RAX
	CALL printfcall ;Print the result
	
	;print XMM0 and XMM1
	MOVSD QWORD [RSP], XMM0 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat;This preserves all registers

	MOVSD QWORD [RSP], XMM1 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat;This preserves all registers


	SUBSD XMM1, XMM0
	MOVSD QWORD [RSP], XMM1 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat;This preserves all registers

	;Calculate 2^XMM1
	MOVSD QWORD [RSP], XMM1 ;Copy the remainder back to the stack
	FLD QWORD [RSP];Load the remainder to the fpu stack ST(0)
	F2XM1 ; ST(0) = 2^ST(0) - 1
	;Pop th resutl back to cpu stack
	FSTP QWORD [RSP]
	MOVSD XMM0, QWORD [RSP];load back to sse for return value (floating point)
	
	MOVSD QWORD [RSP], XMM0 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat;This preserves all registers

	;Add one to the result
	CALL addone ;ADDSS XMM0

	MOVSD QWORD [RSP], XMM0 ;Copy to stack
	MOV RDI, QWORD [RSP]
	CALL printfcallfloat;This preserves all registers

	ADD RSP, 8;restore stack
	ADD RSP, 8
	RET


	;Multiply with the whole number we got from the exponentiation subroutine
	;Load the rax to sse (whole number in rax)
	SUB RSP, 4
	MOV DWORD [RSP], EAX
	MOVD XMM1, DWORD [RSP]
	ADD RSP, 4

	MULSD XMM0, XMM1 ;Result in XMM0

	;FLD RAX;Load to the fpu stack from RAX, now we have exponentiated
	
	;SUBSD

	ADD RSP, 8;Reset the stack
	ADD RSP, 8
	RET

twotopwr:
	;RDI contains the power
	;CALL printfcall
	PUSH RBX;Preserve rbx
	CMP RDI, 0;If 0 then return 1
	JE ret1
	
	MOV RAX, 2 ;2 here, starting value
	MOV RBX, 2 ;Multiplier
	
loop:
	;CALL printfcall
	DEC RDI ;Subtract the exponent
	CMP RDI, 0 ;Check if 0
	JE ret ;if 0 then return the value in rax
	MUL RBX ;Multiply rax with 2
	;Print the rax content
	;PUSH RDI
	;PUSH RAX
	;MOV RDI, RAX
	;CALL printfcall
	;POP RAX
	;POP RDI

	JMP loop ;Again
ret1:
	MOV RAX, 1;Exponent was 0
ret:
	POP RBX
	;return value in rax
	RET
