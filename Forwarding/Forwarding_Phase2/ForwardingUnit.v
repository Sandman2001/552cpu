/*
    Forwarding Unit - Andrew Sanders 4/2/2025
    Inputs:
        MEM_WB_RegWrite: Write enable signal for MEM/WB register
        EX_MEM_RegWrite: Write enable signal for EX/MEM register
        ID_EX_MemWrite: Write enable signal for ID/EX register
        MEM_WB_Rd: Destination register address for MEM/WB register
        EX_MEM_Rd: Destination register address for EX/MEM register
        ID_EX_Rt: Destination/source register address for ID/EX register
        ID_EX_Rs: Source register address for ID/EX register


    Outputs:
        ForwardA: Forwarding signal for ALU input 1
        ForwardB: Forwarding signal for ALU input 2

    How to use this module:
        - Connect the inputs to the corresponding signals in the ID/EX and EX/MEM/MEM/WB registers
        - Connect the outputs to the Muxes in the ALU
        - Connect the ForwardMem output to the Mem input mux of the Data Memory
    
*/
module ForwardingUnit(
    input MEM_WB_RegWrite, // Write enable signal for MEM/WB register
    input EX_MEM_RegWrite, // Write enable signal for EX/MEM register
    input ID_EX_MemWrite, // Write enable signal for ID/EX register
    input [3:0] MEM_WB_Rd, // Destination register address for MEM/WB register
    input [3:0] EX_MEM_Rd, // Destination register address for EX/MEM register
    input [3:0] EX_MEM_Rt, // Destination/source register address for EX/MEM register
    input [3:0] ID_EX_Rt, // Destination/source register address for ID/EX register
    input [3:0] ID_EX_Rs, // Source register address for ID/EX register
    input [3:0] ALU_OpCode,
    output [1:0] ForwardA, // Forwarding signal for ALU input 1
    output [1:0] ForwardB, // Forwarding signal for ALU input 2
    output ForwardMem // Forwarding signal for Mem stage
);

//forwarding logic: forward A

    assign ForwardA = (EX_MEM_RegWrite & EX_MEM_Rd != 4'b0000 & EX_MEM_Rd == ID_EX_Rs) ? 2'b10 : // Ex Hazard rs
                      (MEM_WB_RegWrite & MEM_WB_Rd != 4'b0000 & MEM_WB_Rd == ID_EX_Rs           
                      & (EX_MEM_RegWrite & EX_MEM_Rd != 4'b0000 & (EX_MEM_Rd != ID_EX_Rs))) ? 2'b01 : // if the result in Mem stage is more recent, ignore this forward
                      2'b00; // No hazard

//forwarding logic: forward B
    assign ForwardB = (EX_MEM_RegWrite & EX_MEM_Rd != 4'b0000 & EX_MEM_Rd == ID_EX_Rt & (ALU_OpCode != 4'b1010 & ALU_OpCode != 4'b1011))  ? 2'b10 : // Ex Hazard rt
                      (MEM_WB_RegWrite & MEM_WB_Rd != 4'b0000 & MEM_WB_Rd == ID_EX_Rt             //mem hazard rt
                      & (EX_MEM_RegWrite & EX_MEM_Rd != 4'b0000 & (EX_MEM_Rd != ID_EX_Rt))) ? 2'b01 : // if the result in Mem stage is more recent, ignore this forward
                      2'b00; // No hazard
//if ( MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)and (MEM/WB.RegisterRd = EX/MEM.RegisterRt) ) enable MEM-to-MEM forwarding
    assign ForwardMem = (MEM_WB_RegWrite & MEM_WB_Rd != 4'b0000 & MEM_WB_Rd == EX_MEM_Rt) ? 1'b1 : // Mem to mem forwarding
                        1'b0; // No hazard
endmodule


