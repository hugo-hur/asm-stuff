[bits 64]
;Strcpy
global strcpytest
strcpytest:
	;We have another string in rdi, another one in rsi copy rsi to rdi
	
.loop:
	;RDX, RCX käytössä
	;have to move the value from the address to a register before cmp
	;mov ax, [rsi]
	;cmp ax, 0
	cmp byte [rsi], 0;We want to compare the 8 lsb
	je .return
	
	mov dx, [rsi]
	;Have to copy again the value to the reg?
	mov [rdi], dx;Copy to the address given from the rdi reg
	;Copied
	inc rsi;Next char
	inc rdi
	jmp .loop
	
.return:
	;Add null terminator
	mov [rdi], byte 0;Tell the assebler that we want to give a 8 bit value
	ret