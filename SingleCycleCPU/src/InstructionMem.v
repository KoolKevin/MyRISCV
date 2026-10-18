module InstructionMem(
    input   [5:0] address,  // max 64 indirizzi  
    output [31:0] instruction
);
    // array che modella la memoria contenente le istruzioni
    reg [31:0] memory[0:63];  
    
    // inizializziamo la memoria con il contenuto di un file
    initial begin
        $readmemh("data/InstructionMem_h.txt", memory);  
    end
        
    assign instruction = memory[address];   

endmodule

