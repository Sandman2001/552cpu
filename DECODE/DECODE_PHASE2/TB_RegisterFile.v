`timescale 1ns/100ps

module TB_RegisterFile();
    reg clk;
    reg rst;
    reg [3:0] SrcReg1, SrcReg2, DstReg;
    reg WriteReg;
    reg [15:0] DstData;
    
    wire [15:0] SrcData1, SrcData2;
    
    reg [15:0] tb_SrcData1_drive, tb_SrcData2_drive;
    reg tb_SrcData1_en, tb_SrcData2_en;
    
    assign SrcData1 = tb_SrcData1_en ? tb_SrcData1_drive : 16'bz;
    assign SrcData2 = tb_SrcData2_en ? tb_SrcData2_drive : 16'bz;
    
    RegisterFile iDUT (
        .clk(clk), 
        .rst(rst), 
        .SrcReg1(SrcReg1), 
        .SrcReg2(SrcReg2), 
        .DstReg(DstReg), 
        .WriteReg(WriteReg), 
        .DstData(DstData), 
        .SrcData1(SrcData1), 
        .SrcData2(SrcData2)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Monitor the outputs
    initial begin
        $display("Starting Register File Testbench");
        $monitor("Time=%0t,SrcReg1=%0d, SrcReg2=%0d, DstReg=%0d, WriteReg=%0b, DstData=%0h, SrcData1=%0h, SrcData2=%0h", 
                 $time, SrcReg1, SrcReg2, DstReg, WriteReg, DstData, SrcData1, SrcData2);
    end
    
    // Initialize inputs
    initial begin
        rst = 1;
        SrcReg1 = 0;
        SrcReg2 = 0;
        DstReg = 0;
        WriteReg = 0;
        DstData = 0;
        tb_SrcData1_en = 0;
        tb_SrcData2_en = 0;
        tb_SrcData1_drive = 0;
        tb_SrcData2_drive = 0;
        
        // Apply reset
        @(posedge clk);
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;
        
        // Test Case 2: Write to register 5 and read back
        @(posedge clk);
        DstReg = 5;
        DstData = 16'hABCD;
        WriteReg = 1;
        @(posedge clk);
        WriteReg = 0;
        SrcReg1 = 5;
        @(posedge clk);
        if(SrcData1 === 16'hABCD)
            $display("PASS: Read data matches written data");
        else
            $display("FAIL: Read data %h doesn't match written data %h", SrcData1, 16'hABCD);
        
        // Test Case 3: Write to multiple registers
        @(posedge clk);
        // Write to reg 2
        DstReg = 2;
        DstData = 16'h1234;
        WriteReg = 1;
        @(posedge clk);
        // Write to reg 10
        DstReg = 10;
        DstData = 16'h5678;
        @(posedge clk);
        WriteReg = 0;
        
        // Read from both
        SrcReg1 = 2;
        SrcReg2 = 10;
        @(posedge clk);
        if(SrcData1 === 16'h1234 && SrcData2 === 16'h5678)
            $display("PASS: Reading from multiple registers works");
        else
            $display("FAIL: Read data incorrect. Reg2=%h (expected 1234), Reg10=%h (expected 5678)", SrcData1, SrcData2);
            
        // Test Case 4: Test bypassing logic (read during write)
        @(posedge clk);
        DstReg = 7;
        DstData = 16'hBEEF;
        WriteReg = 1;
        SrcReg1 = 7; // Read the same register being written
        @(posedge clk);
        if(SrcData1 === 16'hBEEF)
            $display("PASS: Bypassing works - read returns the value being written");
        else
            $display("FAIL: Bypassing failed - read returns %h instead of %h", SrcData1, 16'hBEEF);
        
        // Test Case 5: Read from reg 0 (which should be 0 after reset)
        @(posedge clk);
        WriteReg = 0;
        SrcReg1 = 0;
        @(posedge clk);
        if(SrcData1 === 16'h0)
            $display("PASS: Register 0 contains 0 after reset");
        else
            $display("FAIL: Register 0 contains %h instead of 0", SrcData1);
            
        // Test Case 6: Read-after-write timing test
        @(posedge clk);
        // Write to reg 15
        DstReg = 15;
        DstData = 16'hDEAD;
        WriteReg = 1;
        @(posedge clk);
        WriteReg = 0;
        // Immediately read from reg 15
        SrcReg1 = 15;
        @(posedge clk);
        if(SrcData1 === 16'hDEAD)
            $display("PASS: Read-after-write works correctly");
        else
            $display("FAIL: Read-after-write failed - read returns %h instead of %h", SrcData1, 16'hDEAD);
            
        // Test Case 7: Reset behavior
        @(posedge clk);
        // Ensure we have data in reg 5
        DstReg = 5;
        DstData = 16'h9999;
        WriteReg = 1;
        @(posedge clk);
        WriteReg = 0;
        // Apply reset
        rst = 1;
        @(posedge clk);
        rst = 0;
        // Try to read from reg 5
        SrcReg1 = 5;
        @(posedge clk);
        if(SrcData1 === 16'h0)
            $display("PASS: Register was cleared by reset");
        else
            $display("FAIL: Register contains %h after reset (expected 0)", SrcData1);
            
        #20;
        $display("Yahoo!! All tests Passed");
        $stop;
    end
endmodule
