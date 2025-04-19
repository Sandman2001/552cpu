/*The list of instructions and their opcodes are summarized in Table 3 below.
Table 3: Table of opcodes
Instruction	Opcode
ADD	0000  *NEEDS TO ADDD*
SUB	0001
XOR	0010
RED	0011
SLL	0100
SRA	0101
ROR	0110  
PADDSB	0111
LW	1000  *NEEDS TO ADD*
SW	1001  *NEEDS TO ADD*
LLB	1010
LHB	1011
B	1100  *Done in Br_addr module on its own*
BR	1101  *Done in Br_addr module on its own*
PCS	1110
HLT	1111
*/


module ALU (ALU_In1, ALU_In2, Opcode , ALU_Out, Ovfl, Neg, Zero
            //Flag_Write
            );
    input [15:0] ALU_In1, ALU_In2;
    input [3:0] Opcode; 
    output [15:0] ALU_Out;
    output Ovfl; // Just to show overflow
    output Neg; // Just to show negative
    output Zero; // Just to show zero
    // output Flag_Write; // Signal that enable to actually wire to flag register

    wire [15:0] addsub_out;
    wire add;  //0 whan need to add, 1 when need to sub

    wire [15:0] xor_out;  //ouput of XOR operation
    wire [15:0] Red_sum;  //output of RED operation
    wire [15:0] Shift_out;  //output of shift operation

    wire [15:0] PADDSB_out;  //output of PADDSB operation

    wire [15:0] LLB_out;  //output of LLB operation
    wire [15:0] LHB_out;  //output of LHB operation

    


    assign add = ((Opcode == 4'b0000) | (Opcode == 4'b1000) | (Opcode == 4'b1001) | (Opcode == 4'b1100) | (Opcode == 4'b1101)) ? 0 : 1;  //5 different cases when need to add vals (addSub  adds when sub  is 0)


    /*
        16bit addsub unit adds vlas for operations including ADD, (load word & Store word calc mem address)
    */
    CLA_16bit_AddSub addsub(.A(ALU_In1), .B(ALU_In2), .sub(add), .Error(Ovfl), .Sum(addsub_out));
    assign Neg = addsub_out[15]; //if MSB is 1 than negative flag should be true bc signed binary
    /*
        16bit XOR
    */
    assign xor_out = ALU_In1 ^ ALU_In2;

    /*
        16bit reduction tree for RED operation
    */
    RED_CLA_16bit reduction_add(.A(ALU_In1), .B(ALU_In2), .S(Red_sum)); 

    /*
        16bit shift unit for SLL, SRA, ROR operations
    */
    Shifter shift(.Shift_Out(Shift_out), .Shift_In(ALU_In1), .Shift_Val(ALU_In2[3:0]), .Mode(Opcode[1:0]));

    /*
        16bit PADDSB unit
    */
    PADDSB_16bit padd(.A(ALU_In1), .B(ALU_In2), .Sum(PADDSB_out));

    /*
        16bit LLB unit
    */
    assign LLB_out = ((ALU_In1 & 16'hFF00) | ALU_In2);

    /*
        16bit LHB unit
    */
    assign LHB_out = ((ALU_In1 & 16'h00FF) | (ALU_In2 << 8));

    assign ALU_Out = (Opcode == 4'b0000) ? addsub_out :  //ADD
                     (Opcode == 4'b0001) ? addsub_out :  //SUB
                     (Opcode == 4'b0010) ? xor_out :  //XOR
                     (Opcode == 4'b0011) ? Red_sum :  //RED
                     (Opcode == 4'b0100) ? Shift_out :  //SLL
                     (Opcode == 4'b0101) ? Shift_out :  //SRA
                     (Opcode == 4'b0110) ? Shift_out :  //ROR
                     (Opcode == 4'b0111) ? PADDSB_out :  //PADDSB
                     (Opcode == 4'b1000) ? addsub_out :  //LW (mem address calculation through add)
                     (Opcode == 4'b1001) ?  addsub_out:  //SW (mem address calculation through add)
                     (Opcode == 4'b1010) ? LLB_out :  //LLB
                     (Opcode == 4'b1011) ? LHB_out :  //LHB
                     ALU_In1; //Default so dont care about these outputs 
    
    // assign Flag_Write = (Opcode == 4'b0000) ? 1 :  //ADD
    //                     (Opcode == 4'b0001) ? 1 :  //SUB
    //                     (Opcode == 4'b0010) ? 1 :  //XOR
    //                     (Opcode == 4'b0100) ? 1 :  //SLL
    //                     (Opcode == 4'b0101) ? 1 :  //SRA
    //                     (Opcode == 4'b0110) ? 1 :  //ROR
    //                     0;  //Default so dont care about these outputs
                        
    assign Zero = (ALU_Out == 16'h0000); //if output is 0 than zero flag should be true
endmodule

