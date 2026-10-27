`timescale 1ns/1ps

module PipelinedRISCV(
    input clk,
    input reset
);
    // NB: i segnali usano come suffisso lo stadio della pipeline di appartenenza
    reg [31:0] PC_fetch, PC_decode, PC_execute;
    reg [31:0] PCPlus4_fetch, PCPlus4_decode, PCPlus4_execute, PCPlus4_memory, PCPlus4_writeback;
    reg [31:0] instruction_fetch, instruction_decode;
    wire [31:0] PCBranchTarget_execute;
    reg [31:0] immExtended_decode, immExtended_execute;
    reg [4:0] addressDestReg_decode, addressDestReg_execute, addressDestReg_memory, addressDestReg_writeback;
    reg [31:0] writebackData;
    reg [4:0] addressSourceReg1_decode, addressSourceReg1_execute;
    reg [4:0] addressSourceReg2_decode, addressSourceReg2_execute;
    reg [31:0] sourceReg1Data_decode, sourceReg1Data_execute;
    reg [31:0] sourceReg2Data_decode, sourceReg2Data_execute;
    reg [31:0] forwardingData2;
    reg [31:0] ALUOperand1, ALUOperand2;
    reg [31:0] ALUResult_execute, ALUResult_memory, ALUResult_writeback;
    wire ALUResultIsZero;
    reg [31:0] dataMemReadData_memory, dataMemReadData_writeback;
    reg [31:0] dataMemWriteData_execute, dataMemWriteData_memory;

    // segnali della control unit
    reg RFWriteEnable_decode, RFWriteEnable_execute, RFWriteEnable_memory, RFWriteEnable_writeback;
    reg [1:0] writebackSrc_decode, writebackSrc_execute, writebackSrc_memory, writebackSrc_writeback;
    reg dataMemWriteEnable_decode, dataMemWriteEnable_execute, dataMemWriteEnable_memory;
    reg isBranch_decode, isBranch_execute;
    reg isJump_decode, isJump_execute;
    reg [2:0] ALUOpcode_decode, ALUOpcode_execute;
    reg ALUSrc2_decode, ALUSrc2_execute;
    wire [1:0] immSrc_decode;
    wire nextPCSrc_execute;

    // segnali della hazard detection unit
    wire [1:0] forwardALUOperand1, forwardALUOperand2;
    wire stallFetch, stallDecode;
    wire flushExecute;


    // ------------ IF stage ------------ //

	// Program Counter logic
    assign PCPlus4_fetch = PC_fetch + 32'd4;
    assign PCBranchTarget_execute = PC_execute + immExtended_execute;
    // TODO: aggiungi supporto per istruzioni jump
    wire [31:0] nextPC_fetch = nextPCSrc_execute ? PCBranchTarget_execute : PCPlus4_fetch;
	always @ (posedge clk, posedge reset) 
        if (reset)
            PC_fetch <= 32'h00001000; // default program counter 
        else if (!stallFetch)
            PC_fetch <= nextPC_fetch;
        // else 
        //    we're stalling and we need to keep fetching the same instruction 

    InstructionMem imem (
        .address(PC_fetch[7:2]), // le istruzioni sono 4 byte e ne ho max 64
        .instruction(instruction_fetch)
    );            

    // IF/ID pipeline register 
    always @ (posedge clk) begin
        if (!stallDecode) begin
            PC_decode <= PC_fetch;
            PCPlus4_decode <= PCPlus4_fetch;
            instruction_decode <= instruction_fetch;
        end
        // else 
        //    we're stalling and we need to keep decoding the same instruction 
    end

    // ------------ ID stage ------------ //

    assign addressSourceReg1_decode = instruction_decode[19:15];
    assign addressSourceReg2_decode = instruction_decode[24:20];
    assign addressDestReg_decode = instruction_decode[11:7];
    // Apprezziamo gli encoding dei registri nelle istruzioni riscv
    RegisterFile rf (
        .clk(clk),
        .reset(reset),
        .addressSourceReg1(instruction_decode[19:15]),
        .addressSourceReg2(instruction_decode[24:20]),
        .addressDestReg(addressDestReg_writeback),
        .writeEnable(RFWriteEnable_writeback),
        .destRegData(writebackData),
        .sourceReg1Data(sourceReg1Data_decode),
        .sourceReg2Data(sourceReg2Data_decode)
    );

    ImmExtensionUnit ext (
        .instr(instruction_decode[31:7]),
        .immSrc(immSrc_decode),
        .immExtended(immExtended_decode)
    );

    // i segnali di controlli vengono generati durante la decodifica dell'istr-
    // -uzione, per poi essere propagati e consumati negli stadi successivi
    ControlUnit controlUnit (
        .op(instruction_decode[6:0]),
        .funct3(instruction_decode[14:12]),
        .funct7(instruction_decode[31:25]),
        .RFWriteEnable(RFWriteEnable_decode),
        .immSrc(immSrc_decode),
        .ALUSrc2(ALUSrc2_decode),
        .dataMemWriteEnable(dataMemWriteEnable_decode),
        .writebackSrc(writebackSrc_decode),
        .ALUOpcode(ALUOpcode_decode),
        .isBranch(isBranch_decode),
        .isJump(isJump_decode)
    );

    // ID/EX pipeline register
    always @ (posedge clk) begin
        if (flushExecute) begin
            // NB: qua l'importante è disabilitare tutti i segnali di controllo
            // che agiscono come un write-enable (e.g. RFWriteEnable), in questo
            // modo lo stato del processore non viene modificato durante i cicli
            // di stallo. Imposto comunque tutti i segnali a 0 in modo da poter
            // osservare più facilmente le bolle nella pipeline durante debug
            sourceReg1Data_execute <= 32'd0;
            sourceReg2Data_execute <= 32'd0;
            PC_execute <= 32'd0; 
            PCPlus4_execute <= 32'd0;
            immExtended_execute <= 32'd0;
            addressDestReg_execute <= 5'd0;
            addressSourceReg1_execute <= 5'd0;
            addressSourceReg2_execute <= 5'd0;
            // segnali di controllo
            RFWriteEnable_execute <= 1'd0;
            writebackSrc_execute <= 2'd0;
            dataMemWriteEnable_execute <= 1'd0;
            isBranch_execute <= 1'd0;
            isJump_execute <= 1'd0; 
            ALUOpcode_execute <= 3'd0;
            ALUSrc2_execute <= 1'd0;
        end else begin 
            sourceReg1Data_execute <= sourceReg1Data_decode;
            sourceReg2Data_execute <= sourceReg2Data_decode;
            PC_execute <= PC_decode; 
            PCPlus4_execute <= PCPlus4_decode;
            immExtended_execute <= immExtended_decode;
            addressDestReg_execute <= addressDestReg_decode;
            addressSourceReg1_execute <= addressSourceReg1_decode;
            addressSourceReg2_execute <= addressSourceReg2_decode;
            // segnali di controllo
            RFWriteEnable_execute <= RFWriteEnable_decode;
            writebackSrc_execute <= writebackSrc_decode;
            dataMemWriteEnable_execute <= dataMemWriteEnable_decode;
            isBranch_execute <= isBranch_decode;
            isJump_execute <= isJump_decode; 
            ALUOpcode_execute <= ALUOpcode_decode;
            ALUSrc2_execute <= ALUSrc2_decode;
        end
    end

    // ------------ EX stage ------------ //

    // questo è puramente un alias per non fare confusione coi nomi
    assign dataMemWriteData_execute = forwardingData2;

    // due mux a 3 vie che implementano le connessioni di forwarding agli
    // operandi della ALU
    always @(*) begin
        case(forwardALUOperand1)
            2'b00: ALUOperand1 = sourceReg1Data_execute;
            2'b01: ALUOperand1 = writebackData;
            2'b10: ALUOperand1 = ALUResult_memory;
            default: ALUOperand1 = 32'bx;
        endcase

        case(forwardALUOperand2)
            2'b00: forwardingData2 = sourceReg2Data_execute;
            2'b01: forwardingData2 = writebackData;
            2'b10: forwardingData2 = ALUResult_memory;
            default: forwardingData2 = 32'bx;
        endcase
    end

    assign ALUOperand2 = ALUSrc2_execute ? immExtended_execute : forwardingData2;
    ALU alu (
        .opcode(ALUOpcode_execute),
        .op1(ALUOperand1),
        .op2(ALUOperand2),
        .result(ALUResult_execute),
        .resultIsZero(ALUResultIsZero)
    );

    // pc = pc + imm if: branch taken (beq == 0), or when doing a jump
    // (questo adesso lo devo mettere fuori dalla control unit dato che isBranch
    // e isJump devono essere campionati dai registri della pipeline)
    assign nextPCSrc_execute = (isBranch_execute & ALUResultIsZero) | isJump_execute; 

    // EX/MEM pipeline register
    always @ (posedge clk) begin
        ALUResult_memory <= ALUResult_execute;
        dataMemWriteData_memory <= dataMemWriteData_execute;
        addressDestReg_memory <= addressDestReg_execute;
        PCPlus4_memory <= PCPlus4_execute;

        // segnali di controllo
        RFWriteEnable_memory <= RFWriteEnable_execute;
        writebackSrc_memory <= writebackSrc_execute;
        dataMemWriteEnable_memory <= dataMemWriteEnable_execute;
    end

    // ------------ MEM stage ------------ //

    DataMem dmem (
        .clk(clk),
        .writeEnable(dataMemWriteEnable_memory),
        // TODO: per adesso lascio anche la dmem word-addressable (supporto 
        // solo lw, e sw)
        .address(ALUResult_memory[7:2]), // addressing mode riscv -> registro + offset
        .writeData(dataMemWriteData_memory),
        .readData(dataMemReadData_memory)
    );

    // MEM/WB pipeline register
    always @ (posedge clk) begin
        ALUResult_writeback <= ALUResult_memory;
        dataMemReadData_writeback <= dataMemReadData_memory;
        addressDestReg_writeback <= addressDestReg_memory;
        PCPlus4_writeback <= PCPlus4_memory;

        // segnali di controllo
        RFWriteEnable_writeback <= RFWriteEnable_memory;
        writebackSrc_writeback <= writebackSrc_memory;
    end

    // ------------ WB stage ------------ //

    // mux a 3 vie per dst operand del RF
    always @(*)
        case(writebackSrc_writeback)
            2'b00: writebackData = ALUResult_writeback;
            2'b01: writebackData = dataMemReadData_writeback;
            2'b10: writebackData = PCPlus4_writeback;
            default: writebackData = 32'bx;
        endcase

    HazardDetectionUnit hazardDetectionUnit (
        .addressSourceReg1_execute(addressSourceReg1_execute),
        .addressSourceReg2_execute(addressSourceReg2_execute),
        .addressDestReg_memory(addressDestReg_memory),
        .addressDestReg_writeback(addressDestReg_writeback),
        .RFWriteEnable_memory(RFWriteEnable_memory),
        .RFWriteEnable_writeback(RFWriteEnable_writeback),
        .forwardALUOperand1(forwardALUOperand1),
        .forwardALUOperand2(forwardALUOperand2),

        .loadInExecute(writebackSrc_execute[0]),
        .addressDestReg_execute(addressDestReg_execute),
        .addressSourceReg1_decode(addressSourceReg1_decode),
        .addressSourceReg2_decode(addressSourceReg2_decode),
        .stallFetch(stallFetch),
        .stallDecode(stallDecode),
        .flushExecute(flushExecute)
    );

endmodule
