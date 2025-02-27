module PADDSB_16_bit_tb();

    // Declare test signals
    reg [15:0] A, B;
    reg sub;
    wire [15:0] Sum;

    // Instantiate the DUT
    PADDSB_16bit dut(.A(A), .B(B), .sub(sub), .Sum(Sum));

    // Helper function to calculate expected result
    function [3:0] saturated_add;
        input [3:0] a, b;
        input sub;
        reg [4:0] temp;
        begin
            temp = sub ? a - b : a + b;
            if (sub) begin
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

    // Test stimulus
    initial begin
        $monitor("Time=%0t A=%h B=%h sub=%b Sum=%h", $time, A, B, sub, Sum);
        
        // Test case 1: Basic addition without saturation
        sub = 0;
        A = 16'h1234;
        B = 16'h1111;
        #10;
        
        // Test case 2: Addition with positive saturation
        A = 16'h7777;
        B = 16'h1111;
        #10;
        
        // Test case 3: Addition with negative saturation
        A = 16'h8888;
        B = 16'h8888;
        #10;
        
        // Test case 4: Basic subtraction without saturation
        sub = 1;
        A = 16'h4444;
        B = 16'h1111;
        #10;
        
        // Test case 5: Subtraction with positive saturation
        A = 16'h7777;
        B = 16'h8888;
        #10;
        
        // Test case 6: Subtraction with negative saturation
        A = 16'h8888;
        B = 16'h7777;
        #10;

        // Add verification
        verify_result();
        
        $finish;
    end

    // Verification task
    task verify_result;
        reg [15:0] expected;
        reg [3:0] nibble_result;
        integer i;
        begin
            // First nibble (bits 3:0)
            nibble_result = saturated_add(A[3:0], B[3:0], sub);
            expected[3:0] = nibble_result;
            
            // Second nibble (bits 7:4)
            nibble_result = saturated_add(A[7:4], B[7:4], sub);
            expected[7:4] = nibble_result;
            
            // Third nibble (bits 11:8)
            nibble_result = saturated_add(A[11:8], B[11:8], sub);
            expected[11:8] = nibble_result;
            
            // Fourth nibble (bits 15:12)
            nibble_result = saturated_add(A[15:12], B[15:12], sub);
            expected[15:12] = nibble_result;
            
            if (Sum !== expected) begin
                $display("Error at time %0t:", $time);
                $display("A=%h, B=%h, sub=%b", A, B, sub);
                $display("Expected: %h", expected);
                $display("Got     : %h", Sum);
            end else begin
                $display("Test passed at time %0t", $time);
            end
        end
    endtask
endmodule

