module imm_proc(
    mem_instruction, // 16-bit memory instruction input
    imd_choice,      // 2-bit instruction type input
    se_instruction   // 16-bit sign-extended instruction output
);

    // Port declarations in the same order as in the module header:
    input  [15:0] mem_instruction;
    input  [1:0]  imd_choice;
    output [15:0] se_instruction;
    
    // Function to perform the sign or zero extension.
    function [15:0] extend;
        input [15:0] mem_inst;
        input [1:0] choice;
        begin
            case (choice)
                // Branch offset: 9-bit sign-extended (bits [8:0]) then shifted left by 1.
                2'b00: extend = ({{7{mem_inst[8]}}, mem_inst[8:0]} << 1);
                // Memory offset: 4-bit sign-extended (bits [3:0]).
                2'b01: extend = {{12{mem_inst[3]}}, mem_inst[3:0]};
                // Immediate value: 8-bit sign-extended (bits [7:0]).
                2'b10: extend = {{8{mem_inst[7]}}, mem_inst[7:0] << 1};
                // Zero extension: zero-extend the lower 8 bits. (LLB, LHB)
                2'b11: extend = {8'b0, mem_inst[7:0]};
                // Default: output zero.
                default: extend = 16'd0; 
            endcase
        end
    endfunction

endmodule

