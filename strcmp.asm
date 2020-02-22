;Testing helpers asm (intel syntax)

global strcmptest
strcmptest:
	;We have another string in rdi, another one in rsi
.loop:
	mov dx, [rdi];Copy the char from the first string to the dx reg (16 bit)
	mov ax, [rsi];Copy the char from the second string to the ar reg
	
	cmp dx, ax;Compare the char at the strings 
	jne .false;If result is nonzero then return false
	;Chars were equal, check if null
	cmp ax, 0
	je .true;End and all were equal, return true
	;We still have chars to compare, get next ones and loop
	inc rdi;Get the next char from the strings
	inc rsi
	
	jmp .loop
	
.true:
	mov rax, 1
	ret
.false:
	mov rax, 0
	ret