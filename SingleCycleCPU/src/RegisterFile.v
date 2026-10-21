`timescale 1ns/1ps

module RegisterFile(
    input clk,
    input reset,
    // 32 registri
    input [4:0] addressSourceReg1, addressSourceReg2, addressDestReg,
    input writeEnable,
    input [31:0] destRegData,
    output [31:0] sourceReg1Data, sourceReg2Data
);

    reg [31:0] registers[31:0];
    integer i;

    always @(posedge clk, posedge reset)
        if (reset) 
            for (i = 0; i < 32; i = i+1)
                registers[i] <= i[31:0]; // imposto ogni registro al proprio indice
        else if (writeEnable) 
            registers[addressDestReg] <= destRegData;

    // register 0 hardwired to 0
    assign sourceReg1Data = (addressSourceReg1 != 0) ? registers[addressSourceReg1] : 0;
    assign sourceReg2Data = (addressSourceReg2 != 0) ? registers[addressSourceReg2] : 0;

endmodule
