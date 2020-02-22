#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
//Assembly fuctions, will be available after linking
void strcpytest(char* to, char* from);
uint64_t test(uint64_t in);
bool strcmptest(const char* first, const char* second);
void main(void){
	
	printf("%dd\n",test(1));
	const char* f = "yhy";
	if(strcmptest(f, "yhy")){
		printf("Were equal\n");
	}
	if(!strcmptest(f, "abc")){
		printf("Second was not equal\n");
	}
	
	char* str1 = "abcdefg";
	char to[20];
	to[1] = '\0';
	strcpytest(to, str1);
	printf("%s",to);
}