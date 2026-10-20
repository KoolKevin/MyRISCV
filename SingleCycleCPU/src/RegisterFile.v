`timescale 1ns/1ps

module RegisterFile(
    input clk,
    // 32 registri
    input [4:0] addressSourceReg1, addressSourceReg2, addressDestReg,
    input writeEnable,
    input [31:0] destRegData,
    output [31:0] sourceReg1Data, sourceReg2Data
);

    reg [31:0] rf[31:0];

    always @(posedge clk)
        if (writeEnable) 
            rf[addressDestReg] <= destRegData;

    // register 0 hardwired to 0
    assign sourceReg1Data = (addressSourceReg1 != 0) ? rf[addressSourceReg1] : 0;
    assign sourceReg2Data = (addressSourceReg2 != 0) ? rf[addressSourceReg2] : 0;

endmodule
