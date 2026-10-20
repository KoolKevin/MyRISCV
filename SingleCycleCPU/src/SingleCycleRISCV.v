`timescale 1ns/1ps

module SingleCycleRISCV(
    input clk,
    input reset,
);
    reg [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] immExtended;
    wire [31:0] destRegData,
    wire [31:0] sourceReg1Data,
    wire [31:0] sourceReg2Data,
    wire [31:0] ALUOperand2;
    wire [31:0] ALUResult;
    wire ALUResultIsZero;
    wire [31:0] dataMemReadData;
    // segnali della control unit
    input nextPCSRC;
    input [1:0] immSrc;
    input RFWriteEnable;
    input ALUSrc2;
    input [2:0] ALUOpcode;
    input dataMemWriteEnable;
    input writebackSrc;

	// Program Counter logic
    wire PCPlus4 = PC + 32'd4;
    wire PCBranchTarget = PC + immExtended;
    // TODO: aggiungi supporto per istruzioni jump
    wire nextPC = nextPCSrc ? PCBranchTarget : PCPlus4;
	always @ (posedge clk, posedge reset) 
        if (reset)
            PC <= 32'h00001000; // default program counter 
        else
            PC <= nextPC;

    InstructionMem imem (
        .address(PC[7:2]), // le istruzioni sono 4 byte e ne ho max 64
        .instruction(instruction);
    );            

    // TODO: Control Unit

    assign destRegData = writebackSrc ? dataMemReadData : ALUResult;
    // Apprezziamo gli encoding dei registri nelle istruzioni riscv
    RegisterFile rf (
        .clk(clk),
        .addressSourceReg1(instr[19:15]),
        .addressSourceReg2(instr[24:20]),
        .addressDestReg(instr[11:7]),
        .writeEnable(RFWriteEnable),
        .destRegData(destRegData),
        .sourceReg1Data(sourceReg1Data),
        .sourceReg2Data(sourceReg2Data)
    );

    ImmExtensionUnit ext (
        .instr(instruction[31:7]),
        .immSrc(immSrc),
        .immExtended(immExtended)
    );

    // TODO: ALU logic
    assign ALUOperand2 = ALUSrc2 ? immExtended : sourceReg2Data;
    ALU alu (
        .ALUOpcode(ALUOpcode),
        .ALUOp1(sourceReg1Data),
        .ALUOp2(ALUOperand2),
        .ALUResult(ALUResult),
        .ALUResultIsZero(ALUResultIsZero)
    );

    DataMem(
        .clk(clk),
        .writeEnable(dataMemWriteEnable),
        .address(ALUResult), // addressing mode riscv -> registro + offset
        .writeData(sourceReg2Data),
        .readData(dataMemReadData)
    );

endmodule
