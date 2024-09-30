The nano7 language interpreter uses built-in variables. Their scope is global. Variables are identified by the English ABC letters ("A","B","C" .."Z").

A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

"A" is an array expandable up to 32k, the elements of which can contain 4-byte signed integers. By default, only the first element (A.0) exists.

Syntax: A.0 = 16 or

A.9 = 16 or

B = 9
A.B = 16 or

B = 9
C = 2
A.B = C * 8

"B".."Q" are used to store 4-byte signed integer values.

"R" Writing R sets the maximum value of the random number generator and reading R results in a random number that falls between 0 and the set maximum value (-1). By default, this maximum value is 100, and the largest number that can be generated is 99.

"S".."Z" stores a single 1-byte integer value. when printing, the PRN instruction evaluates the stored value as an ASCII code.

Arithmetic and logical operators:

+ (add)  - (sub)  * (mul) / (div (integer))
< (less) > (more) = (equal)

Var assignment:
The operator of assignment is "=". Syntax:

B = number (integer)
B = 12

B = variable
B = C

B = variable arithmetic op number
B = C + 12

B = variable arithmetic op variable
B = C - D 

B = INP (INPUT must be 4 bytes signed integer only)

Keywords:

IF
The IF must be followed by a logical condition, which, if true, will execute the code following the condition (the end of the line). If the condition is not true, the execution moves to the next line.

Syntax: IF B > A.0 PRN B

No THEN and no ELSE! Only the IF keyword, the CONDITION and the instruction (
PRN or JMP or ASSIGN). Red, blue, black:

IF  B > A.0  PRN B

JMP
Jump instruction that must be followed by a tag that the interpreter detected and registered when reading the script. The return address (line) stored in the variable named 'stack'. Lol

Syntax: JMP .LABEL_ONE

RET
This is the additional (RETurn) statement for labels. If this is included in one of the lines after the label, then after the RET line, the code execution returns to the line+1 where it was before jumping to the label. Thus, lines written between a LABEL and a RET instruction become a subroutine.

Syntax:

.SUB_LABEL
 B = B * 2
 IF B = C PRN S
 IF B > C PRN T 
RET

PRN
Print statement, which must be followed by at least one variable identifier. The PRN instruction cannot directly print numbers or characters, only values ​​of variables. It interprets the values ​​of the S..Z variables as ASCII code and prints the character corresponding to the code. For example:

T = 65
PRN T

Output: A

NOP
No code execution occurs. The purpose of the instruction is to separate two labels below one another so that they do not end up at the same address.

INP
Reads a signed integer value from the keyboard.

The syntax:

B = INP or
A.4 = INP or
A.B = INP

------------------------------------------------------------------
------------------------------------------------------------------

The classical structure of a nano7 script: 

JMP .BEGIN

.SUB_INC
 IF B < C  B = B + 1
 PRN B S
RET

.BEGIN
 B = 1
 C = 5
 S = 32
 T = 10

.LOOP
 JMP .SUB_INC
 IF B = C JMP .END
 JMP .LOOP

.END

Here is the oputput (with TRC):

1
2 2
3 3
4 4
5
-------------- (32 lines done) - Code:
 1  JMP .BEGIN
 2  IF B < C B = B + 1
 3  PRN B S
 4  RET
 5  B = 1
 6  C = 5
 7  S = 32
 8  T = 10
 9  PRN B T
10  JMP .SUB_INC
11  IF B = C JMP .END
12  JMP .LOOP

-------------- Label(s):
.SUB_INC  2
.BEGIN    5
.LOOP     9
.END      13

-------------- Vars (B..Z):
B 5
C 5
R 100
S 32
T 10
-------------- Array element(s):
A.0 = 0
