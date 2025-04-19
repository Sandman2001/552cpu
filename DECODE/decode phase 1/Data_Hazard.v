module data_hazard(
    input        EX_MEM_ReadMem,    // True if previous instruction is a load
    input  [3:0] RS,                // Current instruction's source register 1
    input  [3:0] RT,                // Current instruction's source register 2
    input  [3:0] EX_MEM_RD,         // Previous instruction's destination register
    input        is_br_instr,         // True if current instruction is a branch
    output       stall              // Stall signal: true if hazard detected
);

    // Load-use hazard: if previous is a load and its destination is used by current instruction
    wire load_use_hazard;
    assign load_use_hazard = EX_MEM_ReadMem && 
                             ((EX_MEM_RD == RS) || (EX_MEM_RD == RT));

    // Branch hazard: branch instructions require their source operands to be ready,
    // and do not benefit from forwarding.
    wire branch_hazard;
    assign branch_hazard = is_br_instr && 
                           ((EX_MEM_RD == RS) || (EX_MEM_RD == RT));

    // If either hazard is detected, we stall.
    assign stall = load_use_hazard || branch_hazard;

endmodule
