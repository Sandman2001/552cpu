/*Module: OPFlags
The eight possible conditions are Equal (EQ), Not Equal (NEQ), Greater Than (GT), Less Than (LT), Greater Than or Equal (GTE), Less Than or Equal (LTE), Overflow (OVFL) and Unconditional (UNCOND). Many of these conditions are determined based on the 3-bit flag N, V, and Z.  The instructions that set these flags are outlined in Table 2 below:
Table 2: Flags set by instructions
Instruction	Flags Set
ADD	N, Z, V
SUB	N, Z, V
XOR	Z
SLL	Z
SRA	Z
ROR	Z
A true condition corresponds to a taken branch. The status of the condition is obtained from the FLAG register (the definition of each flag is in Section 3.3). 
Flag bits are stored in the FLAG register and used in conditional branches. There are three bits in the FLAG register: Zero (Z), Overflow (V), and Sign (N). Only the arithmetic instructions (except PADDSB and RED) can change the three flags (Z, V, N).  
The logical instructions (XOR, SLL, SRA, ROR) change the Z FLAG, but they do not change the N or V flag.
The Z flag is set if and only if the output of the operation is zero. 
The V flag is set by the ADD and SUB instructions if and only if the operation results in an overflow. Overflow must be set based on treating the arithmetic values as 16-bit signed integers.  
The N flag is set if and only if the result of the ADD or SUB instruction is negative.
Other Instructions, including load/store instructions and control instructions, do not change the contents of the FLAG register. */

module OPFlags(
    input [15:0] Result,
    input [2:0] Opcode,
    input Error,
    output [2:0] Flags
);
    // Define flag positions in output
    // Flags[2] = N (Sign), Flags[1] = V (Overflow), Flags[0] = Z (Zero)
    
    // Zero flag logic - set if Result is zero for arithmetic and logical ops
    assign Flags[1] = (Result == 16'h0000);
    
    // Sign flag logic - set if Result is negative (MSB=1) for arithmetic ops only
    assign Flags[2] = (Opcode == 3'b000 || Opcode == 3'b001) ? Result[15] : Flags[2];
    
    // Overflow flag logic - only for ADD (000) and SUB (001)
    assign Flags[0] = Error; // Placeholder 
    
endmodule
