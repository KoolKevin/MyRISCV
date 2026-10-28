`timescale 1ns/1ps

module HazardDetectionUnit(
    // per forwarding
    input [4:0] addressSourceReg1_execute,
    input [4:0] addressSourceReg2_execute,
    input [4:0] addressDestReg_memory,
    input [4:0] addressDestReg_writeback,
    input RFWriteEnable_memory,
    input RFWriteEnable_writeback,
    output reg [1:0] forwardALUOperand1,
    output reg [1:0] forwardALUOperand2,
    // per stalli relativi a load
    input loadInExecute,
    input [4:0] addressDestReg_execute,
    input [4:0] addressSourceReg1_decode,
    input [4:0] addressSourceReg2_decode,
    output stallFetch,
    output stallDecode,
    output flushExecute,
    // per stalli relativi a dipendenze di controllo
    input branchIsTaken,
    output flushDecode
);

    // Forwarding logic
    //
    // Forwarding is necessary when an instruction in the Execute stage has a 
    // source register matching the destination register of an instruction in 
    // the Memory or Writeback stage. x0 is hardwired to 0 and should never be
    // forwarded. If both the Memory and Writeback stages contain matching 
    // destination registers, then the Memory stage should have priority because
    // it contains the more recently executed instruction
    always @(*) begin
        // forward from memory stage
        if (
            (
                (addressSourceReg1_execute == addressDestReg_memory) & RFWriteEnable_memory
            ) & (addressSourceReg1_execute != 5'd0)
        )
            forwardALUOperand1 = 2'b10;
        // forward from writeback stage
        else if (
            (
                (addressSourceReg1_execute == addressDestReg_writeback) & RFWriteEnable_writeback
            ) & (addressSourceReg1_execute != 5'd0)
        )
            forwardALUOperand1 = 2'b01;
        // no forwarding, use RF output
        else
            forwardALUOperand1 = 2'b00;

        // forward from memory stage
        if (
            (
                (addressSourceReg2_execute == addressDestReg_memory) & RFWriteEnable_memory
            ) & (addressSourceReg2_execute != 5'd0)
        )
            forwardALUOperand2 = 2'b10;
        // forward from writeback stage
        else if (
            (
                (addressSourceReg2_execute == addressDestReg_writeback) & RFWriteEnable_writeback
            ) & (addressSourceReg2_execute != 5'd0)
        )
            forwardALUOperand2 = 2'b01;
        // no forwarding, use RF output
        else
            forwardALUOperand2 = 2'b00;
    end

    // stalling logic
    //
    // a stall is needed for load RAW dependencies and for taken branches, since
    // by default the pipeline statically predicts that they are not taken.
    //
    // In order for the Hazard Unit to stall the pipeline, the following 
    // conditions must be met:
    // 1. A load word is in the Execute stage (writebackSource_execute[0] == 1) 
    // 2. The load’s destination register (addressDestReg_execute) matches 
    //    addressSource1Reg_decode or addressSource2Reg_decode, the source operands
    //    of the instruction in the Decode stage
    wire lwStall = loadInExecute & (
        (addressDestReg_execute == addressSourceReg1_decode) | 
        (addressDestReg_execute == addressSourceReg2_decode)
    );
    assign stallFetch = lwStall;
    assign stallDecode = lwStall;
    assign flushExecute = lwStall | branchIsTaken;
    assign flushDecode = branchIsTaken;

    // nota: The lwStall logic described here could cause the processor to stall
    // unnecessarily when the destination of the load is x0 or when a false
    // dependency exists — that is, when the instruction in the Decode stage is
    // a J- or I-type instruction that randomly causes a false match between 
    // bits in their immediate fields and the destination register. However,
    // these cases are rare (and poor coding practice, in the case of x0 being
    // the load destination) and they cause only a small performance loss.

endmodule
