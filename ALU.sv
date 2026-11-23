//This is the main ALU where the big the arithmetic operations happen
//Ian


/*
0000	ADD
0001	SUB
0010	AND
0011	OR
0100	XOR
0101	SLL
0110	SRL
0111	SRA
1000	SLT
1001	SLTU
*/
/*
generate the following outputs
Zero
Negative
Carry (1=no borrow)
Overflow
*/

//make the ALUout multiplexer have pasthrough on 0 and the register active on 1