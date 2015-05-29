//HELLOWORLD My first program written in C++
// HELLOWORLD is the first program I've written using the C++ programming language
//
//	Written by Josh Grooms on 20130727

/*	Preprocessor directive (includes the contents of another file)
	IOSTREAM is part of the standard library & helps display the function output.
	IOSTREAM is the header file here */
#include <iostream>

/*	The function header. 
	INT indicates that the function will return an integer. 
	MAIN indicates the starting point of the program & must be included in all functions */
int main()
{
	/*	STD is the standard namespace
		COUT is an object called from the STD namespace. It displays the output in the console window.
		<< dictates what is to be funneled into the object preceding these characters
		ENDL moves the cursor to the next line, where new text is to be displayed
		Semicolons are needed at the end of every single statement (line entry) in C++ */
	std::cout << "Hello World!" << std::endl;
	
	// Return ends the program. 0 is the output
	return 0;
}