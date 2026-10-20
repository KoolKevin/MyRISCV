`timescale 1ns/1ps

module SingleCycleCPU(
    input clk,
    input reset
);
    reg [31:0] PC;

	// program counter
	always @ (posedge clk, posedge reset) 
        if (reset)
            PC <= 32'h00000000; // default program counter 
        else
            PC <= NextPC;

    InstructionMem imem (
        .address(),
        .instruction()
    );            

    DataMem(
        .clk(),
        .address(),
        .writeEnable(),
        .writeData(),
        .readData()
    );

    RegisterFile rf (
        .clk(),
        .addressSourceReg1(),
        .addressSourceReg2(),
        .addressDestReg(),
        .writeEnable(),
        .destRegData(),
        .sourceReg1Data(),
        .sourceReg2Data()
    );

endmodule
