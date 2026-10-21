module ALU(
    input  [2:0]  opcode,
    input  [31:0] op1, op2,
    output reg [31:0] result,
    output resultIsZero
);
    // devo fattorizzare via questo altrimenti warning nel caso slt
    wire [31:0] subResult = op1 - op2; 

    always @ (*)
        case (opcode)
            3'b000:  result = op1 + op2;                // add
            3'b001:  result = subResult;                // sub
            3'b010:  result = op1 & op2;                // and
            3'b011:  result = op1 | op2;                // or
            3'b100:  result = op1 ^ op2;                // xor
            3'b101:  result = {31'b0, subResult[31]};   // slt
            // nota: posso shiftare di al massimo 32 posizioni
            3'b110:  result = op1 << op2[4:0];          // sll
            3'b111:  result = op1 >> op2[4:0];          // srl
            default: result = 32'bx;
        endcase

    assign resultIsZero = (result == 32'b0);
  
endmodule
