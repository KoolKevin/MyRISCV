`timescale 1ns/1ps

module SingleCycleRISCV(
    input clk,
    input reset
);
    reg [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] immExtended;
    reg [31:0] destRegData;
    wire [31:0] sourceReg1Data;
    wire [31:0] sourceReg2Data;
    wire [31:0] ALUOperand2;
    wire [31:0] ALUResult;
    wire ALUResultIsZero;
    wire [31:0] dataMemReadData;
    // segnali della control unit
    wire RFWriteEnable;
    wire [1:0] immSrc;
    wire ALUSrc2;
    wire dataMemWriteEnable;
    wire [1:0] writebackSrc;
    wire [2:0] ALUOpcode;
    wire nextPCSrc;

	// Program Counter logic
    wire [31:0] PCPlus4 = PC + 32'd4;
    wire [31:0] PCBranchTarget = PC + immExtended;
    // TODO: aggiungi supporto per istruzioni jump
    wire [31:0] nextPC = nextPCSrc ? PCBranchTarget : PCPlus4;
	always @ (posedge clk, posedge reset) 
        if (reset)
            PC <= 32'h00001000; // default program counter 
        else
            PC <= nextPC;

    InstructionMem imem (
        .address(PC[7:2]), // le istruzioni sono 4 byte e ne ho max 64
        .instruction(instruction)
    );            

    ControlUnit controlUnit (
        .op(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .zero(ALUResultIsZero),

        .RFWriteEnable(RFWriteEnable),
        .immSrc(immSrc),
        .ALUSrc2(ALUSrc2),
        .dataMemWriteEnable(dataMemWriteEnable),
        .writebackSrc(writebackSrc),
        .ALUOpcode(ALUOpcode),
        .nextPCSrc(nextPCSrc)
    );

    // mux a 3 vie
    always @(*)
        case(writebackSrc)
            2'b00: destRegData = ALUResult;
            2'b01: destRegData = dataMemReadData;
            2'b10: destRegData = PCPlus4;
            default: destRegData = 32'bx;
        endcase

    // Apprezziamo gli encoding dei registri nelle istruzioni riscv
    RegisterFile rf (
        .clk(clk),
        .reset(reset),
        .addressSourceReg1(instruction[19:15]),
        .addressSourceReg2(instruction[24:20]),
        .addressDestReg(instruction[11:7]),
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

    assign ALUOperand2 = ALUSrc2 ? immExtended : sourceReg2Data;
    ALU alu (
        .opcode(ALUOpcode),
        .op1(sourceReg1Data),
        .op2(ALUOperand2),
        .result(ALUResult),
        .resultIsZero(ALUResultIsZero)
    );

    DataMem dmem (
        .clk(clk),
        .writeEnable(dataMemWriteEnable),
        // TODO: per adesso lascio anche la dmem word-addressable (supporto 
        // solo lw, e sw)
        .address(ALUResult[7:2]), // addressing mode riscv -> registro + offset
        .writeData(sourceReg2Data),
        .readData(dataMemReadData)
    );

endmodule
