module Shifter_tb();
    // Declare testbench signals
    logic [15:0] Shift_In;
    logic [3:0] Shift_Val;
    logic [1:0] Mode;
    logic [15:0] Shift_Out;
    logic [15:0] expected_out;
    
    // Instantiate the Shifter module
    Shifter dut (
        .Shift_Out(Shift_Out),
        .Shift_In(Shift_In),
        .Shift_Val(Shift_Val),
        .Mode(Mode)
    );

    // Helper function to calculate expected output
    function logic [15:0] calc_expected;
        input logic [15:0] in;
        input logic [3:0] shift;
        input logic [1:0] mode;
        logic [15:0] result;
        begin
            case(mode)
                2'b00: result = in << shift; // SLL
                2'b01: result = $signed(in) >>> shift; // SRA 
                2'b10: result = (in >> shift) | (in << (16-shift)); // ROR
                default: result = in;
            endcase
            return result;
        end
    endfunction
    
    // Test stimulus
    initial begin
        // Initialize signals
        Shift_In = 16'h0000;
        Shift_Val = 4'h0;
        Mode = 2'b00;
        
        // Wait for simulation to settle
        #5;
        
        // Test Case 1: Logical Left Shift (SLL)
        $display("Testing Logical Left Shift (SLL)...");
        Mode = 2'b00;
        Shift_In = 16'hABCD;
        
        // Test different shift amounts
        for (int i = 0; i < 16; i++) begin
            Shift_Val = i[3:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("SLL: Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in SLL operation!");
        end
        
        // Test Case 2: Arithmetic Right Shift (SRA)
        $display("\nTesting Arithmetic Right Shift (SRA)...");
        Mode = 2'b01;
        
        // Test positive number
        Shift_In = 16'h7FFF;
        for (int i = 0; i < 16; i++) begin
            Shift_Val = i[3:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("SRA (positive): Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in SRA positive operation!");
        end
        
        // Test negative number
        Shift_In = 16'h8000;
        for (int i = 0; i < 16; i++) begin
            Shift_Val = i[3:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("SRA (negative): Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in SRA negative operation!");
        end
        
        // Test Case 3: Rotate Right (ROR)
        $display("\nTesting Rotate Right (ROR)...");
        Mode = 2'b10;
        Shift_In = 16'hA5A5;
        
        for (int i = 0; i < 16; i++) begin
            Shift_Val = i[3:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("ROR: Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in ROR operation!");
        end
        
        // Additional edge cases
        $display("\nTesting Edge Cases...");
        
        // Test all zeros
        Shift_In = 16'h0000;
        Shift_Val = 4'h4;
        for (int i = 0; i < 3; i++) begin
            Mode = i[1:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("All zeros: Mode=%d, Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Mode, Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in all zeros test!");
        end
        
        // Test all ones
        Shift_In = 16'hFFFF;
        Shift_Val = 4'h4;
        for (int i = 0; i < 3; i++) begin
            Mode = i[1:0];
            expected_out = calc_expected(Shift_In, Shift_Val, Mode);
            #5;
            $display("All ones: Mode=%d, Input=%h, Shift=%d, Output=%h, Expected=%h %s", 
                    Mode, Shift_In, Shift_Val, Shift_Out, expected_out,
                    (Shift_Out === expected_out) ? "Y" : "N");
            if (Shift_Out !== expected_out) $error("Mismatch in all ones test!");
        end
        
        $display("\nSimulation completed!");
        $stop;
    end
    
    // Optional: Add waveform dumping

    
endmodule 