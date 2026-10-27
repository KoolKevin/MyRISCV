`timescale 1ns/1ps

module RegisterFile(
    input clk,
    input reset,
    // 32 registri
    input [4:0] addressSourceReg1, addressSourceReg2, addressDestReg,
    input writeEnable,
    input [31:0] destRegData,
    output reg [31:0] sourceReg1Data, sourceReg2Data
);

    reg [31:0] registers[31:0];
    integer i;

    // in una cpu pipelined le scritture al RF avvengono nel primo semiperiodo
    // mentre le letture nel secondo
    always @(posedge clk, negedge clk, posedge reset) begin
        if (reset) 
            for (i = 0; i < 32; i = i+1)
                registers[i] <= i[31:0]; // imposto ogni registro al proprio indice
        else if (clk == 1 & writeEnable) 
            registers[addressDestReg] <= destRegData;
        else if (clk == 0) begin
            // register 0 hardwired to 0
            if (addressSourceReg1 != 0)
                sourceReg1Data <= registers[addressSourceReg1];
            else
                sourceReg1Data <= 0;

            if (addressSourceReg2 != 0)
                sourceReg2Data <= registers[addressSourceReg2];
            else
                sourceReg2Data <= 0;
        end
    end

endmodule

