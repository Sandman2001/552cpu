module DECODE_tb;
  // Signal declarations
  reg         clk, rst_n;
  reg  [15:0] instruction, PC_plus_2;
  reg  [3:0]  WriteRegAddr;
  reg  [15:0] WriteRegData_Ext;
  reg         Z_flag, N_flag, V_flag;
  wire [15:0] SrcData1, SrcData2, ALU_input_1, ALU_input_2, ImmExt;
  wire [2:0]  ccc;
  wire [3:0]  ALUOp;
  wire        ALUSrc, MemRead, MemWrite, MemToReg, en_PC_inc;
  wire        BranchEn, BranchTaken, FlagWrite, HLT;
  wire [15:0] BranchAddr;
  
  integer test_number, passed_tests, failed_tests;
  
  // Instantiate the DUT
  DECODE dut(
    .clk(clk),
    .rst_n(rst_n),
    .instruction(instruction),
    .PC_plus_2(PC_plus_2),
    .WriteRegAddr(WriteRegAddr),
    .WriteRegData_Ext(WriteRegData_Ext),
    .Z_flag(Z_flag),
    .N_flag(N_flag),
    .V_flag(V_flag),
    .SrcData1(SrcData1),
    .SrcData2(SrcData2),
    .ALU_input_1(ALU_input_1),
    .ALU_input_2(ALU_input_2),
    .ImmExt(ImmExt),
    .ccc(ccc),
    .ALUOp(ALUOp),
    .ALUSrc(ALUSrc),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemToReg(MemToReg),
    .en_PC_inc(en_PC_inc),
    .BranchEn(BranchEn),
    .BranchTaken(BranchTaken),
    .BranchAddr(BranchAddr),
    .FlagWrite(FlagWrite),
    .HLT(HLT)
  );
  
    // Add an initial block to set the initial values
    initial begin
    clk = 1'b0;   // Initialize clock to 0
    rst_n = 1'b0; // Start in reset state
    #10;          // Wait a bit
    rst_n = 1'b1; // Release reset
    end

  // Clock generation using an always block (10 ns period)
  always #5 clk = ~clk;
  
  // Dump waveforms
  initial begin
    $dumpfile("decode_tb.vcd");
    $dumpvars(0, DECODE_tb);
  end
  
  // Task to check test results
  task check_test;
    input [1023:0] test_name;
    input [3:0]    exp_ALUOp;
    input          exp_ALUSrc, exp_MemRead, exp_MemWrite, exp_MemToReg;
    input          exp_en_PC_inc, exp_BranchEn, exp_FlagWrite, exp_HLT;
    input [2:0]    exp_ccc;
    input          exp_BranchTaken;
    input [15:0]   exp_BranchAddr;
    begin
      test_number = test_number + 1;
      if (ALUOp !== exp_ALUOp || ALUSrc !== exp_ALUSrc ||
          MemRead !== exp_MemRead || MemWrite !== exp_MemWrite ||
          MemToReg !== exp_MemToReg || en_PC_inc !== exp_en_PC_inc ||
          BranchEn !== exp_BranchEn || FlagWrite !== exp_FlagWrite ||
          HLT !== exp_HLT || (BranchEn && (ccc !== exp_ccc)) ||
          BranchTaken !== exp_BranchTaken ||
          (BranchTaken && (BranchAddr !== exp_BranchAddr))) begin
        $display("\n[TEST %0d FAILED] %s", test_number, test_name);
        $display("  Instruction: 0x%h", instruction);
        if (ALUOp !== exp_ALUOp)
          $display("  ALUOp: Expected 0x%h, Got 0x%h", exp_ALUOp, ALUOp);
        if (ALUSrc !== exp_ALUSrc)
          $display("  ALUSrc: Expected %b, Got %b", exp_ALUSrc, ALUSrc);
        if (MemRead !== exp_MemRead)
          $display("  MemRead: Expected %b, Got %b", exp_MemRead, MemRead);
        if (MemWrite !== exp_MemWrite)
          $display("  MemWrite: Expected %b, Got %b", exp_MemWrite, MemWrite);
        if (MemToReg !== exp_MemToReg)
          $display("  MemToReg: Expected %b, Got %b", exp_MemToReg, MemToReg);
        if (en_PC_inc !== exp_en_PC_inc)
          $display("  en_PC_inc: Expected %b, Got %b", exp_en_PC_inc, en_PC_inc);
        if (BranchEn !== exp_BranchEn)
          $display("  BranchEn: Expected %b, Got %b", exp_BranchEn, BranchEn);
        if (BranchTaken !== exp_BranchTaken)
          $display("  BranchTaken: Expected %b, Got %b", exp_BranchTaken, BranchTaken);
        if (BranchTaken && (BranchAddr !== exp_BranchAddr))
          $display("  BranchAddr: Expected 0x%h, Got 0x%h", exp_BranchAddr, BranchAddr);
        if (FlagWrite !== exp_FlagWrite)
          $display("  FlagWrite: Expected %b, Got %b", exp_FlagWrite, FlagWrite);
        if (HLT !== exp_HLT)
          $display("  HLT: Expected %b, Got %b", exp_HLT, HLT);
        if (BranchEn && (ccc !== exp_ccc))
          $display("  ccc: Expected %b, Got %b", exp_ccc, ccc);
        failed_tests = failed_tests + 1;
      end else begin
        $display("[TEST %0d PASSED] %s", test_number, test_name);
        passed_tests = passed_tests + 1;
      end
      $display("  Flags: Z=%b, N=%b, V=%b", Z_flag, N_flag, V_flag);
      $display("  SrcData1: 0x%h, SrcData2: 0x%h", SrcData1, SrcData2);
      $display("  ALU_input_1: 0x%h, ALU_input_2: 0x%h", ALU_input_1, ALU_input_2);
      $display("  ImmExt: 0x%h", ImmExt);
      if (BranchEn)
        $display("  BranchAddr: 0x%h, BranchTaken: %b", BranchAddr, BranchTaken);
    end
  endtask
  
  // State machine for the test sequence
  reg [4:0] state;
  localparam INIT             = 5'd0,
             WRITE_R1         = 5'd1,
             WAIT_R1          = 5'd2,
             WRITE_R2         = 5'd3,
             WAIT_R2          = 5'd4,
             WRITE_R3         = 5'd5,
             WAIT_R3          = 5'd6,
             WRITE_R8         = 5'd7,
             WAIT_R8          = 5'd8,
             TEST_ADD_SET     = 5'd9,
             TEST_ADD_CHECK   = 5'd10,
             TEST_BEQ_Z1_SET  = 5'd11,
             TEST_BEQ_Z1_CHECK= 5'd12,
             TEST_BEQ_Z0_SET  = 5'd13,
             TEST_BEQ_Z0_CHECK= 5'd14,
             TEST_GT_Z0_SET   = 5'd15,
             TEST_GT_Z0_CHECK = 5'd16,
             TEST_GT_Z1_SET   = 5'd17,
             TEST_GT_Z1_CHECK = 5'd18,
             TEST_GT_N1_SET   = 5'd19,
             TEST_GT_N1_CHECK = 5'd20,
             TEST_LT_N1_SET   = 5'd21,
             TEST_LT_N1_CHECK = 5'd22,
             TEST_LT_N0_SET   = 5'd23,
             TEST_LT_N0_CHECK = 5'd24,
             TEST_BR_UNCOND_SET = 5'd25,
             TEST_BR_UNCOND_CHECK = 5'd26,
             TEST_BR_NEQ_Z0_SET  = 5'd27,
             TEST_BR_NEQ_Z0_CHECK= 5'd28,
             TEST_BR_NEQ_Z1_SET  = 5'd29,
             TEST_BR_NEQ_Z1_CHECK= 5'd30,
             DONE             = 5'd31;
  
  // Test sequence state machine (clocked)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state              <= INIT;
      // Default signal values
      instruction      <= 16'h0000;
      PC_plus_2        <= 16'h0002;
      WriteRegAddr     <= 4'd0;
      WriteRegData_Ext <= 16'h0000;
      Z_flag           <= 1'b0;
      N_flag           <= 1'b0;
      V_flag           <= 1'b0;
      test_number      <= 0;
      passed_tests     <= 0;
      failed_tests     <= 0;
    end else begin
      case (state)
        INIT: begin
          WriteRegAddr     <= 4'd1;
          WriteRegData_Ext <= 16'h1111;
          state            <= WRITE_R1;
        end
        WRITE_R1: state <= WAIT_R1;
        WAIT_R1: begin
          WriteRegAddr     <= 4'd2;
          WriteRegData_Ext <= 16'h2222;
          state            <= WRITE_R2;
        end
        WRITE_R2: state <= WAIT_R2;
        WAIT_R2: begin
          WriteRegAddr     <= 4'd3;
          WriteRegData_Ext <= 16'h3333;
          state            <= WRITE_R3;
        end
        WRITE_R3: state <= WAIT_R3;
        WAIT_R3: begin
          WriteRegAddr     <= 4'd8;
          WriteRegData_Ext <= 16'h8888;
          state            <= WRITE_R8;
        end
        WRITE_R8: state <= WAIT_R8;
        WAIT_R8: state <= TEST_ADD_SET;
        
        // Test 1: ADD r4, r1, r2 (0x0412)
        TEST_ADD_SET: begin
          instruction <= 16'h0412;
          // (Flags and PC_plus_2 remain as set)
          state <= TEST_ADD_CHECK;
        end
        TEST_ADD_CHECK: begin
          check_test("ADD r4, r1, r2", 
                     4'h0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b0, 1'b1, 1'b0,
                     3'b000, 1'b0, 16'h0000);
          state <= TEST_BEQ_Z1_SET;
        end
        
        // Test 2: B EQ, 100 with Z=1 (0xC264)
        TEST_BEQ_Z1_SET: begin
          instruction <= 16'hC264;
          Z_flag      <= 1'b1;
          N_flag      <= 1'b0;
          V_flag      <= 1'b0;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_BEQ_Z1_CHECK;
        end
        TEST_BEQ_Z1_CHECK: begin
          check_test("B EQ, 100 (Z=1)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b001, 1'b1, 16'h01c8);
          state <= TEST_BEQ_Z0_SET;
        end
        
        // Test 3: B EQ, 100 with Z=0 (0xC264)
        TEST_BEQ_Z0_SET: begin
          instruction <= 16'hC264;
          Z_flag      <= 1'b0;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_BEQ_Z0_CHECK;
        end
        TEST_BEQ_Z0_CHECK: begin
          check_test("B EQ, 100 (Z=0)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b001, 1'b0, 16'h0200);
          state <= TEST_GT_Z0_SET;
        end
        
        // Test 4: B GT, 50 with Z=0, N=0 (0xC432)
        TEST_GT_Z0_SET: begin
          instruction <= 16'hC432;
          Z_flag      <= 1'b0;
          N_flag      <= 1'b0;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_GT_Z0_CHECK;
        end
        TEST_GT_Z0_CHECK: begin
          check_test("B GT, 50 (Z=0, N=0)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b010, 1'b1, 16'h0164);
          state <= TEST_GT_Z1_SET;
        end
        
        // Test 5: B GT, 50 with Z=1, N=0 (0xC432)
        TEST_GT_Z1_SET: begin
          instruction <= 16'hC432;
          Z_flag      <= 1'b1;
          N_flag      <= 1'b0;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_GT_Z1_CHECK;
        end
        TEST_GT_Z1_CHECK: begin
          check_test("B GT, 50 (Z=1, N=0)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b010, 1'b0, 16'h0164);
          state <= TEST_GT_N1_SET;
        end
        
        // Test 6: B GT, 50 with Z=0, N=1 (0xC432)
        TEST_GT_N1_SET: begin
          instruction <= 16'hC432;
          Z_flag      <= 1'b0;
          N_flag      <= 1'b1;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_GT_N1_CHECK;
        end
        TEST_GT_N1_CHECK: begin
          check_test("B GT, 50 (Z=0, N=1)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b010, 1'b0, 16'h0164);
          state <= TEST_LT_N1_SET;
        end
        
        // Test 7: B LT, 25 with N=1 (0xC619)
        TEST_LT_N1_SET: begin
          instruction <= 16'hC619;
          N_flag      <= 1'b1;
          PC_plus_2   <= 16'h0200;
          state       <= TEST_LT_N1_CHECK;
        end
        TEST_LT_N1_CHECK: begin
          check_test("B LT, 25 (N=1)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b011, 1'b1, 16'h0232);
          state <= TEST_LT_N0_SET;
        end
        
        // Test 8: B LT, 25 with N=0 (0xC619)
        TEST_LT_N0_SET: begin
          instruction <= 16'hC619;
          N_flag      <= 1'b0;
          PC_plus_2   <= 16'h0200;
          state       <= TEST_LT_N0_CHECK;
        end
        TEST_LT_N0_CHECK: begin
          check_test("B LT, 25 (N=0)", 
                     4'h0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b011, 1'b0, 16'h0232);
          state <= TEST_BR_UNCOND_SET;
        end
        
        // Test 9: BR UNCOND, r1 (0xDE10)
        TEST_BR_UNCOND_SET: begin
          instruction <= 16'hDE10;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_BR_UNCOND_CHECK;
        end
        TEST_BR_UNCOND_CHECK: begin
          check_test("BR UNCOND, r1", 
                     4'h0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b111, 1'b1, 16'h1111);
          state <= TEST_BR_NEQ_Z0_SET;
        end
        
        // Test 10: BR NEQ, r2 with Z=0 (0xD020)
        TEST_BR_NEQ_Z0_SET: begin
          instruction <= 16'hD020;
          Z_flag      <= 1'b0;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_BR_NEQ_Z0_CHECK;
        end
        TEST_BR_NEQ_Z0_CHECK: begin
          check_test("BR NEQ, r2 (Z=0)", 
                     4'h0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b000, 1'b1, 16'h2222);
          state <= TEST_BR_NEQ_Z1_SET;
        end
        
        // Test 11: BR NEQ, r2 with Z=1 (0xD020)
        TEST_BR_NEQ_Z1_SET: begin
          instruction <= 16'hD020;
          Z_flag      <= 1'b1;
          PC_plus_2   <= 16'h0100;
          state       <= TEST_BR_NEQ_Z1_CHECK;
        end
        TEST_BR_NEQ_Z1_CHECK: begin
          check_test("BR NEQ, r2 (Z=1)", 
                     4'h0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, 1'b1, 1'b0, 1'b0,
                     3'b000, 1'b0, 16'h2222);
          state <= DONE;
        end
        
        DONE: begin
          $display("\n--- DECODE Module Test Summary ---");
          $display("Total tests:  %d", test_number);
          $display("Tests passed: %d", passed_tests);
          $display("Tests failed: %d", failed_tests);
          if (failed_tests == 0)
            $display("ALL TESTS PASSED!");
          else
            $display("SOME TESTS FAILED!");
          #10 $stop;
        end
        
        default: state <= DONE;
      endcase
    end
  end
  
endmodule
