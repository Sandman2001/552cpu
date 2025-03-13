module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
    input [15:0] Shift_In; 	// This is the input data to perform shift operation on
    input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
    input  Mode; 		// To indicate 0=Shift logic Left or 1=Shift Right Arithmetic
    output [15:0] Shift_Out; 	// Shifted output data
    wire [15:0] stage1, stage2, stage4;
	//inside each mux is a ternary operator to decide whether to shiftRA, SLL, or leave as is (inthat order)
	assign stage1 = (Shift_Val[0]) ? (Mode ? {Shift_In[15], Shift_In[15:1]} //shift A right
                                    : {Shift_In[14:0], 1'b0}) :Shift_In; //shift L left or no shift
	assign stage2 = (Shift_Val[1]) ?(Mode ? {{2{stage1[15]}}, stage1[15:2]} //shift A Right 2 bits
                                    : {stage1[13:0], 2'b00}) : stage1; 
	assign stage4 = (Shift_Val[2]) ?(Mode ? {{4{stage2[15]}}, stage2[15:4]} //shift A Right 4 bits 
                                    : {stage2[11:0], 4'h0}) : stage2;
	assign Shift_Out = (Shift_Val[3]) ? (Mode ? {{8{stage4[15]}}, stage4[15:8]} //shift A Right 8 bits
                                    : {stage4[7:0], 8'h00}) : stage4;
endmodule
