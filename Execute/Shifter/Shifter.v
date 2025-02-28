/*The SLL, SRA and ROR instructions perform logical left shift, arithmetic right shift and right rotation, 
respectively, of (rs) by the number of bits specified in the imm field and saves the result in register rd. 
For ROR, bits are rotated off the right (least significant) and are inserted into the vacated bit positions on the left (most significant).
They have the following assembly level syntax:
Opcode rd, rs, imm
The imm field is a 4-bit immediate operand in unsigned representation for the SLL, SRA and ROR instructions. */

module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
    input [15:0] Shift_In; 	// This is the input data to perform shift operation on
    input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
    input  [1:0] Mode; 		// To indicate 0=Shift logic Left, 1=Shift Right Arithmetic, 2=Rotate Right, 3=unused
    output [15:0] Shift_Out; 	// Shifted output data
    wire [15:0] stage1, stage2, stage4;
	//inside each mux is a ternary operator to decide whether to shiftRA, SLL, or leave as is (in that order)
	// Stage 1 - 1 bit shift
	wire [15:0] sll1, sra1, ror1;
	assign sll1 = {Shift_In[14:0], 1'b0};                    // Shift left logical
	assign sra1 = {Shift_In[15], Shift_In[15:1]};           // Shift right arithmetic  
	assign ror1 = {Shift_In[0], Shift_In[15:1]};            // Rotate right
	assign stage1 = Shift_Val[0] ? 
	                (Mode == 2'b00) ? sll1 :
	                (Mode == 2'b01) ? sra1 :
	                (Mode == 2'b10) ? ror1 : 
	                Shift_In : Shift_In;

	// Stage 2 - 2 bit shift
	wire [15:0] sll2, sra2, ror2;
	assign sll2 = {stage1[13:0], 2'b00};                    
	assign sra2 = {{2{stage1[15]}}, stage1[15:2]};         
	assign ror2 = {stage1[1:0], stage1[15:2]};             
	assign stage2 = Shift_Val[1] ?
	                (Mode == 2'b00) ? sll2 :
	                (Mode == 2'b01) ? sra2 :
	                (Mode == 2'b10) ? ror2 :
	                stage1 : stage1;

	// Stage 3 - 4 bit shift  
	wire [15:0] sll4, sra4, ror4;
	assign sll4 = {stage2[11:0], 4'h0};                     
	assign sra4 = {{4{stage2[15]}}, stage2[15:4]};         
	assign ror4 = {stage2[3:0], stage2[15:4]};
	assign stage4 = Shift_Val[2] ?
	                (Mode == 2'b00) ? sll4 :
	                (Mode == 2'b01) ? sra4 :
	                (Mode == 2'b10) ? ror4 :
	                stage2 : stage2;

	// Stage 4 - 8 bit shift
	wire [15:0] sll8, sra8, ror8;  
	assign sll8 = {stage4[7:0], 8'h00};                     
	assign sra8 = {{8{stage4[15]}}, stage4[15:8]};         
	assign ror8 = {stage4[7:0], stage4[15:8]};             
	assign Shift_Out = Shift_Val[3] ?
	                   (Mode == 2'b00) ? sll8 :
	                   (Mode == 2'b01) ? sra8 :
	                   (Mode == 2'b10) ? ror8 :
	                   stage4 : stage4;
endmodule
