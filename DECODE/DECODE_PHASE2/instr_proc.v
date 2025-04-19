module imm_proc(
    input  [15:0] mem_instruction, // 16-bit memory instruction input
    input  [1:0]  imd_choice,      // 2-bit instruction type input
    output reg [15:0] se_instruction // 16-bit sign-extended instruction output
);

always @(*) begin
    case (imd_choice)
        // Branch offset: 9-bit sign-extended (bits [8:0]) then shifted left by 1.
        2'b00: se_instruction = ({{7{mem_instruction[8]}}, mem_instruction[8:0]} << 1);
        // Memory offset: 4-bit sign-extended (bits [3:0]).
        2'b01: se_instruction = {{12{mem_instruction[3]}}, mem_instruction[3:0]};
        // Immediate value: 8-bit sign-extended (bits [7:0]) then shifted left by 1.
        2'b10: se_instruction = ({{8{mem_instruction[7]}}, mem_instruction[7:0]} << 1);
        // Zero extension: zero-extend the lower 8 bits.
        2'b11: se_instruction = {8'b0, mem_instruction[7:0]};
        // Default: output zero.
        default: se_instruction = 16'd0;
    endcase
end

endmodule
