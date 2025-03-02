module ALU_tb();
logic signed [15:0]  ALU_In1, ALU_In2, ALU_Out;
logic signed [3:0] A3, A2, A1, A0, B3, B2, B1, B0;
logic signed [4:0] ae, bf, cg, dh;
logic signed [5:0] ae_bf, cg_dh;
logic [3:0] Opcode;
logic Ovfl, Neg, Zero;
//logic Flag_Write;

logic [7:0] i; //itterator
logic [7:0] byt;
reg [15:0] expected;
reg [3:0] nibble_result;


ALU iDUT(.ALU_In1(ALU_In1), .ALU_In2(ALU_In2), .Opcode(Opcode) , .ALU_Out(ALU_Out), .Ovfl(Ovfl), .Neg(Neg), .Zero(Zero));

initial begin
/*
    Testing adding unit first
    1)checking proper add
    2)checking overflow, zero and negative flags
*/

for(i = 8'h00; i<8'hFF; i = i + 8'h01) begin
    Opcode = 4'h0;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if((ALU_In1[15] == ALU_In2[15]) && (ALU_Out[15] != ALU_In1[15]) && Ovfl != 1 )begin
		$display("overflow is not being detected");
		$stop();
    end
    else if ((Ovfl == 1) && (ALU_In1[15] & ALU_In2[15] & (~ALU_Out[15])) && (ALU_Out != 16'h7FFF)) begin
		$display("Incorrect Pos Saturatioin");
		$stop();
    end
    else if ((Ovfl == 1) && (~ALU_In1[15] & ~ALU_In2[15] & (ALU_Out[15])) && (ALU_Out != 16'h8000)) begin
		$display("Incorrect Neg Saturatioin");
		$stop();
    end
    else if ((Ovfl == 0) && (ALU_Out != ALU_In1+ALU_In2)) begin
            $display("Addition incorrect");
            $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end
    else if (Neg != ALU_Out[15]) begin
        $display("Negative flag not set properly");
        $stop();
    end
    // else if(Flag_Write != 1'b1) begin
    //     $display("Not writing to flag for add");
    //     $stop();
    // end

/*
    Testing subtracting unit
    1)checking proper subtract
    2)checking overflow, zero and negative flags
*/
    Opcode = 4'h1;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;

    if((ALU_In1[15] == ALU_In2[15]) && (ALU_Out[15] != ALU_In1[15]) && Ovfl != 1 )begin
            $display("overflow is not being detected");
            $stop();
    end
    else if ((Ovfl == 1) && (ALU_In1[15] & ALU_In2[15] & (~ALU_Out[15])) && (ALU_Out != 16'h7FFF)) begin
            $display("Incorrect Pos Saturatioin");
            $stop();
    end
    else if ((Ovfl == 1) && (~ALU_In1[15] & ~ALU_In2[15] & (ALU_Out[15])) && (ALU_Out != 16'h8000)) begin
            $display("Incorrect Neg Saturatioin");
            $stop();
    end
    else if ((Ovfl == 0) && (ALU_Out != ALU_In1-ALU_In2)) begin
            $display("Reg subtraction incorrect");
            $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end
    else if (Neg != ALU_Out[15]) begin
        $display("Negative flag not set properly");
        $stop();
    end
    // else if(Flag_Write != 1'b1) begin
    //     $display("Not writing to flag for sub");
    //     $stop();
    // end

    /*
        Testing Bitwise XOR
        1)checking proper XOR
        2)checking to make sure only zero flag is set
    */
    Opcode = 4'h2;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if(ALU_Out != (ALU_In1^ALU_In2)) begin
        $display("XOR incorrect");
	$display((ALU_In1^ALU_In2));
        $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end

    /*
        Testing Reduction unit
        1)making sure reduction is correct
        2)making sure no flags are set
    */
    Opcode = 4'h3;
    A3 = $random;
    A2 = $random;
    A1 = $random;
    A0 = $random;
    B3 = $random;
    B2 = $random;
    B1 = $random;
    B0 = $random;
    ALU_In1 = {A3, A2, A1, A0};
    ALU_In2 = {B3, B2, B1, B0};
    ae = A3 + B3;
    bf = A2 + B2;
    cg = A1 + B1;
    dh = A0 + B0;
    ae_bf = ae + bf;
    cg_dh = cg + dh;
    #1;
    if(ALU_Out != (ae_bf + cg_dh)) begin
        $display("Reduction incorrect");
	$display(((ALU_In1[15:12] + ALU_In2[15:12]) + (ALU_In1[11:8] + ALU_In2[11:8]) + (ALU_In1[7:4] + ALU_In2[7:4]) + (ALU_In1[3:0] + ALU_In2[3:0])));
        $stop();
    end
    // else if(Flag_Write != 1'b0) begin
    //     $display("Flag being incorrectly set");
    //     $stop();
    // end
    
    /*
        Testing SLL works correctly
        1)making sure shift left logical works
	    2)correct zero flag calc
    */
    Opcode = 4'h4;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if(ALU_Out != (ALU_In1 << ALU_In2[3:0])) begin
        $display("SLL incorrect");
        $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end

    /*
        testing to make sure SRA works correctly
        1)making sure shift right arithmetic works
	    2)correct zero flag calc
    */
    Opcode = 4'h5;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if(ALU_Out != (ALU_In1 >>> ALU_In2[3:0])) begin
        $display("SRA incorrect");
        $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end

    /*
        Testing to make sure Rotate right works correctly
        1)making sure rotate right works
	    2)correct zero flag calc
    */
    Opcode = 4'h6;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if(ALU_Out != (ALU_Out = (ALU_In1 >> ALU_In2[3:0]) | (ALU_In1 << (16-ALU_In2[3:0])))) begin
        $display("Rotate right incorrect");
        $stop();
    end
    else if (Zero != ~(&ALU_Out)) begin
        $display("Zero flag not set properly");
        $stop();
    end

    /*
        Testing to make sure PADDSB works properly
        1)making sure the fuctionality works
        2)making sure no flags are set
    */
    Opcode = 4'h7;
    ALU_In1 = $random;
    ALU_In2 = $random;

    #1;

    // First nibble (bits 3:0)
    nibble_result = saturated_add(ALU_In2[3:0], ALU_In2[3:0]);
    expected[4:0] = nibble_result;
    
    // Second nibble (bits 8:4)
    nibble_result = saturated_add(ALU_In2[7:4], ALU_In2[7:4]);
    expected[8:4] = nibble_result;
    
    // Third nibble (bits 11:8)
    nibble_result = saturated_add(ALU_In1[11:8], ALU_In2[11:8]);
    expected[11:8] = nibble_result;
    
    // Fourth nibble (bits 15:12)
    nibble_result = saturated_add(ALU_In1[15:12], ALU_In2[15:12]);
    expected[15:12] = nibble_result;
    
    if (ALU_Out !== expected) begin
        $display("Error at time %0t:", $time);
        $display("A=%h, B=%h", ALU_In1, ALU_In2);
        $display("Expected: %h", expected);
        $display("Got     : %h", ALU_Out);
        $stop();
    end else begin
        $display("Test passed at time %0t", $time);
    end
    
    

    /*
        Testing to make sure Load Word works properly
        1)making sure the fuctionality works
        2)making sure no flags are set
    */
    Opcode = 4'h8;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if((ALU_In1[15] == ALU_In2[15]) && (ALU_Out[15] != ALU_In1[15]) && Ovfl != 1 )begin
		$display("LW overflow is not being detected");
		$stop();
    end
    else if ((Ovfl == 1) && (ALU_In1[15] & ALU_In2[15] & (~ALU_Out[15])) && (ALU_Out != 16'h7FFF)) begin
		$display("LW Incorrect Pos Saturatioin");
		$stop();
    end
    else if ((Ovfl == 1) && (~ALU_In1[15] & ~ALU_In2[15] & (ALU_Out[15])) && (ALU_Out != 16'h8000)) begin
		$display("LW Incorrect Neg Saturatioin");
		$stop();
    end
    else if ((Ovfl == 0) && (ALU_Out != ALU_In1+ALU_In2)) begin
            $display("LW Addition incorrect");
            $stop();
    end

    /*
        Testing to make Store word address calculation works correctly
        1)making sure the fuctionality works
        2)making sure no flags are set
    */
    Opcode = 4'h9;
    ALU_In1 = $random;
    ALU_In2 = $random;
    #1;
    if((ALU_In1[15] == ALU_In2[15]) && (ALU_Out[15] != ALU_In1[15]) && Ovfl != 1 )begin
		$display(" SW overflow is not being detected");
		$stop();
    end
    else if ((Ovfl == 1) && (ALU_In1[15] & ALU_In2[15] & (~ALU_Out[15])) && (ALU_Out != 16'h7FFF)) begin
		$display("SW Incorrect Pos Saturatioin");
		$stop();
    end
    else if ((Ovfl == 1) && (~ALU_In1[15] & ~ALU_In2[15] & (ALU_Out[15])) && (ALU_Out != 16'h8000)) begin
		$display("SW Incorrect Neg Saturatioin");
		$stop();
    end
    else if ((Ovfl == 0) && (ALU_Out != ALU_In1+ALU_In2)) begin
            $display("Sotre word add incorrect");
            $stop();
    end
    // else if (Flag_Write != 1'b0) begin
    //     $display("Flag being incorrectly set");
    //     $stop();
    // end
    /*
        Tasting to make sure LLB works correctly
        1)making sure the fuctionality works
        2)making sure no flags are set
    */
    Opcode = 4'hA;
    ALU_In1 = $random;
    byt = $random;
    ALU_In2 = {8'h00, byt};
    #1;
    if (ALU_Out != (((ALU_In1 & 16'hFF00) | ALU_In2))) begin
        $display("LLB incorrect");
        $stop();
    end
    // else if(Flag_Write != 1'b0) begin
    //     $display("Flag being incorrectly set");
    //     $stop();
    // end

    /*
        Testing to make sure LHB works correctly
        1)making sure the fuctionality works
        2)making sure no flags are set
    */
    Opcode = 4'hB;
    ALU_In1 = $random;
    byt = $random;
    ALU_In2 = {byt, 8'h00};
    #1;
    if (ALU_Out != ((ALU_In1 & 16'h00FF) | (ALU_In2))) begin
        $display("LHB incorrect");
        $stop();
    end
    // else if(Flag_Write != 1'b0) begin
    //     $display("Flag being incorrectly set");
    //     $stop();
    // end
end
$display("YAHOO ALL TESTS PASSED!!!!");
$stop();
end


    // Helper function to calculate expected result
    function [3:0] saturated_add;
        input [3:0] a, b;
       
        reg [4:0] temp;
        begin
            temp = a + b;
            if (temp[4]) begin
                // For subtraction
                if (temp[4] && (a[3] == 0 && b[3] == 1)) // Positive overflow
                    saturated_add = 4'h7;
                else if (!temp[4] && (a[3] == 1 && b[3] == 0)) // Negative overflow
                    saturated_add = 4'h8;
                else
                    saturated_add = temp[3:0];
            end else begin
                // For addition
                if (!temp[4] && (a[3] == 1 && b[3] == 1)) // Negative overflow
                    saturated_add = 4'h8;
                else if (temp[4] && (a[3] == 0 && b[3] == 0)) // Positive overflow
                    saturated_add = 4'h7;
                else
                    saturated_add = temp[3:0];
            end
        end
    endfunction
endmodule