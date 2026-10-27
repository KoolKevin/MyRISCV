`timescale 1ns/1ps

module HazardDetectionUnit(
    input [4:0] addressSourceReg1_execute,
    input [4:0] addressSourceReg2_execute,
    input [4:0] addressDestReg_memory,
    input [4:0] addressDestReg_writeback,
    input RFWriteEnable_memory,
    input RFWriteEnable_writeback,
    output reg [1:0] forwardALUOperand1,
    output reg [1:0] forwardALUOperand2
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
        if (((addressSourceReg1_execute == addressDestReg_memory) & RFWriteEnable_memory) & (addressSourceReg1_execute != 5'd0))
            forwardALUOperand1 = 2'b10;
        // forward from writeback stage
        else if (((addressSourceReg1_execute == addressDestReg_writeback) & RFWriteEnable_writeback) & (addressSourceReg1_execute != 5'd0))
            forwardALUOperand1 = 2'b01;
        // no forwarding, use RF output
        else
            forwardALUOperand1 = 2'b00;

        // forward from memory stage
        if (((addressSourceReg2_execute == addressDestReg_memory) & RFWriteEnable_memory) & (addressSourceReg2_execute != 5'd0))
            forwardALUOperand2 = 2'b10;
        // forward from writeback stage
        else if (((addressSourceReg2_execute == addressDestReg_writeback) & RFWriteEnable_writeback) & (addressSourceReg2_execute != 5'd0))
            forwardALUOperand2 = 2'b01;
        // no forwarding, use RF output
        else
            forwardALUOperand2 = 2'b00;
    end



endmodule
