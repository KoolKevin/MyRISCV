`timescale 1ns/1ps

module DataMem(
    input clk,
    input [5:0] address, // max 64 indirizzi
    input writeEnable,
    input [31:0] writeData,
    output [31:0] readData
);

    // array che modella la memoria
    reg [31:0] memory [0:63];   

    // inizializziamo la memoria con il contenuto di un file
    initial begin
        $readmemh("data/DataMem_h.txt", memory);
    end

	assign readData = memory[address];

    // la scrittura avviene sul fronte positivo del clock
    always @ (posedge clk) begin
        if (writeEnable)
            memory[address] <= writeData;
    end

endmodule
