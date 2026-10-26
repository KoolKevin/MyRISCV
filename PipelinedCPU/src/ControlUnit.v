module ControlUnit(
    input [6:0] op,     // instruction[6:0]
    input [2:0] funct3, // instruction[14:12]
    // nota: questo è come si disabilita (e poi si riabilita) un warnign con
    // verilator
    /* verilator lint_off UNUSEDSIGNAL */
    input [6:0] funct7, // instruction[31:25]
    /* verilator lint_on UNUSEDSIGNAL */
    output RFWriteEnable,
    output [1:0] immSrc,
    output ALUSrc2,
    output dataMemWriteEnable,
    output [1:0] writebackSrc,
    output reg [2:0] ALUOpcode,
    output isBranch,
    output isJump
);

    wire [1:0] ALUOpClass;
    reg [10:0] controlSignals;

    // main decoder
    always @(*)
        case(op)
            // RFWriteEnable_immSrc_ALUSrc2_dataMemWriteEnable_writebackSrc_isBranch_ALUOpClass_isJump
            7'b0000011: controlSignals = 11'b1_00_1_0_01_0_00_0; // I-type (loads)
            7'b0100011: controlSignals = 11'b0_01_1_1_xx_0_00_0; // sw
            7'b0110011: controlSignals = 11'b1_xx_0_0_00_0_10_0; // R–type
            7'b1100011: controlSignals = 11'b0_10_0_0_xx_1_01_0; // beq
            // NB: this new row provides all I-type ALU instructions: andi, ori,
            // and slti. These other instructions share the same op value of
            // 0010011, need the same control signals, and only differ in the
            // funct3 field, which the ALU Decoder already uses to determine
            // ALUControl and, thus, the ALU operation.
            7'b0010011: controlSignals = 11'b1_00_1_0_00_0_10_0; // I-type (alu ops con immediato)
            7'b1101111: controlSignals = 11'b1_11_x_0_10_0_xx_1; // J-type (jal)
            default: controlSignals = 11'bx_xx_x_x_xx_x_xx_x; // ???
        endcase

    assign {RFWriteEnable, immSrc, ALUSrc2, dataMemWriteEnable, writebackSrc, isBranch, ALUOpClass, isJump} = controlSignals;

    // alu decoder: invece di fare un'unica megatabella possiamo spezzare la
    // control unit in due tabelle. ALUOpClass, prodotto dal main decoder, fa
    // una prima classificazione grossolana, processata poi dal seguente blocco 
    // per produrre ALUOpcode
    wire RTypeSub = funct7[5] & op[5]; // TRUE for R–type subtract
    always @(*)
        case(ALUOpClass)
            2'b00: ALUOpcode = 3'b000;              // addition for lw/sw
            2'b01: ALUOpcode = 3'b001;              // subtraction for beq
            default: begin                          // R-type
                case(funct3) 
                    3'b000: if (RTypeSub)
                        ALUOpcode = 3'b001;         // sub
                    else
                        ALUOpcode = 3'b000;         // add
                    3'b010: ALUOpcode = 3'b101;     // slt
                    3'b110: ALUOpcode = 3'b011;     // or
                    3'b111: ALUOpcode = 3'b010;     // and
                    default: ALUOpcode = 3'bxxx;    // ???
                endcase
            end
        endcase
        
endmodule
